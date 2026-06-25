extends Node3D
## Spawns and manages NPC traffic ahead of the player.

const TrafficCarScene: PackedScene = preload("res://scenes/traffic_car.tscn")

const LANE_LEFT_X := -1.85
const LANE_RIGHT_X := 1.85
const SPAWN_MIN_AHEAD := 60.0
const SPAWN_MAX_AHEAD := 160.0
const INITIAL_CAR_COUNT := 6
const DESPAWN_BEHIND := 30.0
const MAX_CARS := 18
const CRASH_GAP := 2.8
const LANE_MATCH_X := 1.2
const MIN_CAR_GAP := 10.0
const LANE_SPAWN_SPACING := 22.0

@export var player_path: NodePath

var _player: Node3D
var _cars: Array[Node3D] = []
var _lane_spawn_z: Dictionary = {
	LANE_LEFT_X: 0.0,
	LANE_RIGHT_X: 0.0,
}


func _ready() -> void:
	if player_path:
		_player = get_node(player_path)
	call_deferred("_spawn_initial_traffic")


func _spawn_initial_traffic() -> void:
	if _player == null:
		return
	var player_z := _player.global_position.z
	_lane_spawn_z[LANE_LEFT_X] = player_z + SPAWN_MIN_AHEAD
	_lane_spawn_z[LANE_RIGHT_X] = player_z + SPAWN_MIN_AHEAD + LANE_SPAWN_SPACING * 0.5
	for i in INITIAL_CAR_COUNT:
		var lane_x := LANE_LEFT_X if i % 2 == 0 else LANE_RIGHT_X
		var world_z: float = _lane_spawn_z[lane_x]
		_spawn_car_at(lane_x, world_z)
		_lane_spawn_z[lane_x] += randf_range(LANE_SPAWN_SPACING, LANE_SPAWN_SPACING + 8.0)


func _physics_process(_delta: float) -> void:
	if _player == null:
		return
	_enforce_car_spacing()
	_cleanup_cars()
	_try_spawn()
	_check_collisions()


func _try_spawn() -> void:
	if _cars.size() >= MAX_CARS:
		return

	var player_z := _player.global_position.z
	var farthest_z := player_z
	for car in _cars:
		farthest_z = maxf(farthest_z, car.global_position.z)

	if farthest_z - player_z < SPAWN_MAX_AHEAD * 0.6:
		var lane_x := LANE_LEFT_X if randf() > 0.5 else LANE_RIGHT_X
		var world_z := _find_clear_spawn_z(lane_x, player_z + randf_range(SPAWN_MIN_AHEAD, SPAWN_MAX_AHEAD))
		_spawn_car_at(lane_x, world_z)


func _spawn_car_at(lane_x: float, world_z: float) -> void:
	var car: Node3D = TrafficCarScene.instantiate()
	car.lane_x = lane_x
	car.position = Vector3(lane_x, 0.0, world_z)
	car.speed_mph = randf_range(40.0, 70.0)
	add_child(car)
	_cars.append(car)
	_lane_spawn_z[lane_x] = maxf(_lane_spawn_z.get(lane_x, world_z), world_z + LANE_SPAWN_SPACING)


func _find_clear_spawn_z(lane_x: float, preferred_z: float) -> float:
	var world_z := preferred_z
	for _attempt in 10:
		if _lane_clear_at(lane_x, world_z):
			return world_z
		world_z += MIN_CAR_GAP
	return world_z


func _lane_clear_at(lane_x: float, world_z: float) -> bool:
	for car in _cars:
		if absf(car.lane_x - lane_x) > LANE_MATCH_X:
			continue
		if absf(car.global_position.z - world_z) < MIN_CAR_GAP:
			return false
	return true


func _enforce_car_spacing() -> void:
	for car in _cars:
		var lead := _get_lead_car_in_lane(car)
		if lead == null:
			continue
		var gap: float = lead.get_rear_z() - car.get_front_z()
		if gap < MIN_CAR_GAP:
			car.speed_mph = minf(car.speed_mph, lead.speed_mph)
		if gap < MIN_CAR_GAP * 0.6:
			car.speed_mph = minf(car.speed_mph, lead.speed_mph * 0.75)


func _get_lead_car_in_lane(car: Node3D) -> Node3D:
	var lead: Node3D = null
	var closest_gap := INF
	for other in _cars:
		if other == car:
			continue
		if absf(other.lane_x - car.lane_x) > LANE_MATCH_X:
			continue
		if other.global_position.z <= car.global_position.z:
			continue
		var gap: float = other.get_rear_z() - car.get_front_z()
		if gap > 0.0 and gap < closest_gap:
			closest_gap = gap
			lead = other
	return lead


func _cleanup_cars() -> void:
	var player_z := _player.global_position.z
	var i := _cars.size() - 1
	while i >= 0:
		var car := _cars[i]
		if car.global_position.z < player_z - DESPAWN_BEHIND:
			car.queue_free()
			_cars.remove_at(i)
		i -= 1


func _check_collisions() -> void:
	var player_front_z := _player_front_z()
	var player_x := _player.global_position.x
	for car in _cars:
		if absf(car.global_position.x - player_x) > LANE_MATCH_X:
			continue
		var gap: float = car.get_rear_z() - player_front_z
		if gap > 0.0 and gap < CRASH_GAP:
			if _player.has_method("trigger_crash"):
				_player.trigger_crash()
			return


func get_closest_ahead() -> Node3D:
	var player_front_z := _player_front_z()
	var player_x := _player.global_position.x
	var closest: Node3D = null
	var closest_gap := INF
	for car in _cars:
		if absf(car.global_position.x - player_x) > LANE_MATCH_X:
			continue
		var gap: float = car.get_rear_z() - player_front_z
		if gap > 0.0 and gap < closest_gap:
			closest_gap = gap
			closest = car
	return closest


func get_following_seconds(player_speed_mph: float) -> float:
	var ahead := get_closest_ahead()
	if ahead == null or player_speed_mph <= 1.0:
		return 99.0
	var gap: float = ahead.get_rear_z() - _player_front_z()
	var speed_ms := player_speed_mph * 0.44704
	return gap / speed_ms


func _player_front_z() -> float:
	if _player.has_method("get_front_z"):
		return _player.get_front_z()
	return _player.global_position.z
