extends Node3D
## NPC traffic vehicle that varies speed and moves along the road.

const MPH_TO_MS := 0.44704
const TARGET_LENGTH := 4.5
const BUS_MODEL_PATH := "res://assets/vw_bus.glb"
const MAX_MESH_AXIS := 100.0

@export var model_rotation_degrees: Vector3 = Vector3.ZERO
@export var model_extra_scale: float = 1.0

var speed_mph: float = 55.0
var lane_x: float = 0.0
var _speed_timer: float = 0.0
var _speed_change_interval: float = 3.0
var _rear_z_offset: float = -TARGET_LENGTH * 0.5
var _front_z_offset: float = TARGET_LENGTH * 0.5


func _ready() -> void:
	position.x = lane_x
	_randomize_speed()
	_speed_change_interval = randf_range(2.5, 6.0)
	_setup_bus_model()


func _physics_process(delta: float) -> void:
	_speed_timer += delta
	if _speed_timer >= _speed_change_interval:
		_speed_timer = 0.0
		_speed_change_interval = randf_range(2.5, 6.0)
		_randomize_speed()

	position.z += speed_mph * MPH_TO_MS * delta


func _setup_bus_model() -> void:
	if not ResourceLoader.exists(BUS_MODEL_PATH):
		push_warning("Bus model not found at %s" % BUS_MODEL_PATH)
		return

	var packed: PackedScene = load(BUS_MODEL_PATH) as PackedScene
	if packed == null:
		push_warning("Failed to load bus model: %s" % BUS_MODEL_PATH)
		return

	var model: Node3D = packed.instantiate()
	model.name = "Model"
	model.rotation_degrees = model_rotation_degrees
	add_child(model)
	call_deferred("_fit_model_to_road", model)


func _fit_model_to_road(model: Node3D) -> void:
	var bounds := _get_mesh_bounds_in_parent_space(model)
	if bounds.size == Vector3.ZERO:
		return

	var length := _estimate_vehicle_length(bounds.size)
	if length > 0.001:
		var fit_scale := (TARGET_LENGTH / length) * model_extra_scale
		model.scale *= Vector3.ONE * fit_scale

	_align_model_to_node(model)
	_cache_extent_offsets()


func _align_model_to_node(model: Node3D) -> void:
	var bounds := _get_mesh_bounds_in_parent_space(model)
	if bounds.size == Vector3.ZERO:
		return

	var center := bounds.get_center()
	model.position -= Vector3(center.x, bounds.position.y, center.z)


func _cache_extent_offsets() -> void:
	var bounds := _get_mesh_bounds_in_parent_space(null)
	if bounds.size == Vector3.ZERO:
		_rear_z_offset = -TARGET_LENGTH * 0.5
		_front_z_offset = TARGET_LENGTH * 0.5
		return

	_rear_z_offset = bounds.position.z
	_front_z_offset = bounds.position.z + bounds.size.z


func _estimate_vehicle_length(size: Vector3) -> float:
	var axes := [size.x, size.y, size.z]
	axes.sort()
	var shortest: float = axes[0]
	var middle: float = axes[1]
	var longest: float = axes[2]

	if longest > MAX_MESH_AXIS and middle > 0.001:
		return middle
	if longest > middle * 8.0 and middle > 0.001:
		return middle
	if longest < 0.001:
		return TARGET_LENGTH
	return longest


func _get_mesh_bounds_in_parent_space(model: Node3D) -> AABB:
	var bounds := AABB()
	var has_bounds := false
	var root := model if model != null else self
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue

		var mesh_bounds := mesh_instance.get_aabb()
		if mesh_bounds.size == Vector3.ZERO:
			continue

		var local_bounds := global_transform.affine_inverse() * mesh_instance.global_transform * mesh_bounds
		if not has_bounds:
			bounds = local_bounds
			has_bounds = true
		else:
			bounds = bounds.merge(local_bounds)

	return bounds


func _randomize_speed() -> void:
	speed_mph = randf_range(35.0, 75.0)


func get_rear_z() -> float:
	return global_position.z + _rear_z_offset


func get_front_z() -> float:
	return global_position.z + _front_z_offset
