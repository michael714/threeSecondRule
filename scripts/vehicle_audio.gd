extends Node3D
## Engine loop and one-shot brake/crash sounds.

@export var player_path: NodePath
@export var brake_path: String = "res://assets/audio/brake.ogg"
@export var crash_path: String = "res://assets/audio/crash.ogg"

var _player: Node3D
var _engine: AudioStreamPlayer
var _brake: AudioStreamPlayer
var _crash: AudioStreamPlayer
var _was_braking: bool = false


func _ready() -> void:
	_engine = $EngineLoop as AudioStreamPlayer
	if _engine != null:
		_engine.pitch_scale = 1.0
		_engine.volume_db = 10.0
		if not _engine.finished.is_connected(_on_engine_finished):
			_engine.finished.connect(_on_engine_finished)
		if not _engine.playing:
			_engine.play()

	if player_path:
		_player = get_node(player_path)
		if _player.has_signal("crashed"):
			_player.crashed.connect(_on_crashed)

	_brake = _make_player("Brake")
	_crash = _make_player("Crash")
	_try_load(_brake, brake_path, false)
	_try_load(_crash, crash_path, false)


func _physics_process(_delta: float) -> void:
	if _player == null or _brake.stream == null:
		return
	var braking := Input.is_action_pressed("brake")
	if braking and not _was_braking:
		_brake.play()
	_was_braking = braking


func _make_player(node_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = &"Master"
	add_child(player)
	return player


func _try_load(player: AudioStreamPlayer, path: String, loop: bool) -> bool:
	if path.is_empty() or not ResourceLoader.exists(path):
		return false
	var stream: AudioStream = load(path)
	if stream == null:
		return false
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = (
			AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
		)
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop
	player.stream = stream
	return true


func _on_engine_finished() -> void:
	if _engine == null:
		return
	if _player != null and _player.is_crashed:
		return
	_engine.play()


func _on_crashed() -> void:
	if _engine != null and _engine.playing:
		_engine.stop()
	if _crash.stream != null:
		_crash.play()
