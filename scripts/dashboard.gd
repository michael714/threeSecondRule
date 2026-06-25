extends Node3D
## Updates the dashboard speedometer LED display.

@export var player_path: NodePath
@export var dashboard_hud_path: NodePath

var _player: Node3D
var _dashboard_hud: Node3D


func _ready() -> void:
	if player_path:
		_player = get_node(player_path)
	if dashboard_hud_path:
		_dashboard_hud = get_node(dashboard_hud_path)
	if _player:
		_player.speed_changed.connect(_on_speed_changed)


func _on_speed_changed(mph: float) -> void:
	if _dashboard_hud and _dashboard_hud.has_method("set_speed_mph"):
		_dashboard_hud.set_speed_mph(mph)
