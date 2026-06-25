extends Node
## Game state, HUD, win/lose for the late-to-work scenario.

const GOAL_MILES := 10.0

@export var player_path: NodePath
@export var traffic_path: NodePath
@export var dashboard_hud_path: NodePath

@onready var _dashboard_hud: Node3D = get_node(dashboard_hud_path)
@onready var _game_over_panel: PanelContainer = $UI/GameOverPanel
@onready var _game_over_title: Label = $UI/GameOverPanel/VBox/TitleLabel
@onready var _game_over_detail: Label = $UI/GameOverPanel/VBox/DetailLabel
@onready var _restart_hint: Label = $UI/GameOverPanel/VBox/RestartHint

var _player: Node3D
var _traffic: Node3D
var _game_over: bool = false


func _ready() -> void:
	_player = get_node(player_path)
	_traffic = get_node(traffic_path)
	_player.speed_changed.connect(_on_speed_changed)
	_player.distance_traveled_changed.connect(_on_distance_changed)
	_player.crashed.connect(_on_crashed)
	_game_over_panel.visible = false
	_update_hud()


func _process(_delta: float) -> void:
	if _game_over:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return
	_update_following_time()


func _on_speed_changed(_mph: float) -> void:
	pass


func _on_distance_changed(miles: float) -> void:
	var remaining := maxf(0.0, GOAL_MILES - miles)
	if _dashboard_hud.has_method("set_distance_miles"):
		_dashboard_hud.set_distance_miles(remaining)
	if miles >= GOAL_MILES and not _game_over:
		_show_win(miles)


func _update_following_time() -> void:
	var seconds: float = _traffic.get_following_seconds(_player.speed_mph)
	if _dashboard_hud.has_method("set_following_gap"):
		_dashboard_hud.set_following_gap(seconds)


func _on_crashed() -> void:
	if _game_over:
		return
	_game_over = true
	_game_over_panel.visible = true
	_game_over_title.text = "Crash!"
	_game_over_detail.text = "You hit the car ahead. Remember the 3-second rule."
	_restart_hint.text = "Press Enter to try again"


func _show_win(miles: float) -> void:
	_game_over = true
	_game_over_panel.visible = true
	_game_over_title.text = "You made it!"
	_game_over_detail.text = "Arrived at work after %.1f miles. Great driving." % miles
	_restart_hint.text = "Press Enter to play again"


func _update_hud() -> void:
	_on_distance_changed(0.0)
	_update_following_time()
