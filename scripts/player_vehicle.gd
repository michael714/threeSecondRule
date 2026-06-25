extends Node3D
## First-person player vehicle: speed, hold-to-accelerate/brake controls.

signal speed_changed(mph: float)
signal crashed
signal distance_traveled_changed(miles: float)

const MPH_TO_MS := 0.44704
const MS_TO_MPH := 2.23694
const MIN_SPEED_MPH := 0.0
const MAX_SPEED_MPH := 120.0

const BASE_ACCEL_MPH := 8.0
const ACCEL_RAMP_MPH := 18.0
const BASE_DECEL_MPH := 10.0
const DECEL_RAMP_MPH := 22.0
const BASE_BRAKE_MPH := 25.0
const BRAKE_RAMP_MPH := 45.0

const LANE_LEFT_X := -1.85
const LANE_RIGHT_X := 1.85
const LANE_CHANGE_SPEED := 9.0

var speed_mph: float = 45.0
var distance_meters: float = 0.0
var is_crashed: bool = false
var target_lane_x: float = LANE_RIGHT_X

var _accel_hold: float = 0.0
var _decel_hold: float = 0.0
var _brake_hold: float = 0.0


func _physics_process(delta: float) -> void:
	if is_crashed:
		return

	_handle_lane_input()
	_update_lane_position(delta)
	_update_speed(delta)
	_apply_movement(delta)
	speed_changed.emit(speed_mph)


func _handle_lane_input() -> void:
	if Input.is_action_just_pressed("lane_left"):
		target_lane_x = LANE_RIGHT_X
	elif Input.is_action_just_pressed("lane_right"):
		target_lane_x = LANE_LEFT_X


func _update_lane_position(delta: float) -> void:
	position.x = move_toward(position.x, target_lane_x, LANE_CHANGE_SPEED * delta)


func _update_speed(delta: float) -> void:
	if Input.is_action_pressed("brake"):
		_brake_hold += delta
		_accel_hold = 0.0
		_decel_hold = 0.0
		var brake_rate := BASE_BRAKE_MPH + _brake_hold * BRAKE_RAMP_MPH
		speed_mph = maxf(MIN_SPEED_MPH, speed_mph - brake_rate * delta)
	elif Input.is_action_pressed("accelerate"):
		_accel_hold += delta
		_decel_hold = 0.0
		_brake_hold = 0.0
		var accel_rate := BASE_ACCEL_MPH + _accel_hold * ACCEL_RAMP_MPH
		speed_mph = minf(MAX_SPEED_MPH, speed_mph + accel_rate * delta)
	elif Input.is_action_pressed("decelerate"):
		_decel_hold += delta
		_accel_hold = 0.0
		_brake_hold = 0.0
		var decel_rate := BASE_DECEL_MPH + _decel_hold * DECEL_RAMP_MPH
		speed_mph = maxf(MIN_SPEED_MPH, speed_mph - decel_rate * delta)
	else:
		_accel_hold = 0.0
		_decel_hold = 0.0
		_brake_hold = 0.0


func _apply_movement(delta: float) -> void:
	var speed_ms := speed_mph * MPH_TO_MS
	distance_meters += speed_ms * delta
	position.z += speed_ms * delta
	distance_traveled_changed.emit(distance_meters / 1609.344)


func get_speed_ms() -> float:
	return speed_mph * MPH_TO_MS


func get_front_z() -> float:
	return global_position.z + 1.8


func trigger_crash() -> void:
	if is_crashed:
		return
	is_crashed = true
	speed_mph = 0.0
	crashed.emit()
