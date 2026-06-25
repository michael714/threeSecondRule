extends Node3D
## Recycles road segments as the player drives forward.

const SEGMENT_LENGTH := 40.0
const SEGMENT_COUNT := 12
const ROAD_WIDTH := 10.5
const LANE_WIDTH := 3.7

@export var player_path: NodePath

var _player: Node3D
var _segments: Array[Node3D] = []


func _ready() -> void:
	if player_path:
		_player = get_node(player_path)
	for i in SEGMENT_COUNT:
		var seg := _create_segment()
		seg.position.z = i * SEGMENT_LENGTH
		add_child(seg)
		_segments.append(seg)


func _physics_process(_delta: float) -> void:
	if _player == null:
		return
	var player_z := _player.global_position.z
	for seg in _segments:
		if seg.position.z + SEGMENT_LENGTH < player_z - SEGMENT_LENGTH:
			var max_z := _get_farthest_z()
			seg.position.z = max_z + SEGMENT_LENGTH


func _get_farthest_z() -> float:
	var max_z := -INF
	for seg in _segments:
		max_z = maxf(max_z, seg.position.z)
	return max_z


func _create_segment() -> Node3D:
	var root := Node3D.new()

	var asphalt := MeshInstance3D.new()
	var asphalt_mesh := BoxMesh.new()
	asphalt_mesh.size = Vector3(ROAD_WIDTH, 0.15, SEGMENT_LENGTH)
	asphalt.mesh = asphalt_mesh
	asphalt.position.y = -0.075
	var asphalt_mat := StandardMaterial3D.new()
	asphalt_mat.albedo_color = Color(0.22, 0.22, 0.24)
	asphalt.material_override = asphalt_mat
	root.add_child(asphalt)

	var shoulder_left := _make_shoulder(-ROAD_WIDTH * 0.5 - 1.25)
	var shoulder_right := _make_shoulder(ROAD_WIDTH * 0.5 + 1.25)
	root.add_child(shoulder_left)
	root.add_child(shoulder_right)

	root.add_child(_make_stripe(0.0, Color(0.95, 0.85, 0.2), 0.12))
	root.add_child(_make_stripe(-LANE_WIDTH * 0.5, Color(0.95, 0.95, 0.95), 0.08))
	root.add_child(_make_stripe(LANE_WIDTH * 0.5, Color(0.95, 0.95, 0.95), 0.08))
	root.add_child(_make_edge_line(-ROAD_WIDTH * 0.5))
	root.add_child(_make_edge_line(ROAD_WIDTH * 0.5))
	root.add_child(_make_roadside_pole(-ROAD_WIDTH * 0.5 - 3.0))
	root.add_child(_make_roadside_pole(ROAD_WIDTH * 0.5 + 3.0))

	return root


func _make_roadside_pole(x: float) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.08
	mesh.bottom_radius = 0.1
	mesh.height = 1.2
	mesh_inst.mesh = mesh
	mesh_inst.position = Vector3(x, 0.55, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.52, 0.48, 1.0)
	mesh_inst.material_override = mat
	return mesh_inst


func _make_shoulder(x: float) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.5, 0.12, SEGMENT_LENGTH)
	mesh_inst.mesh = mesh
	mesh_inst.position = Vector3(x, -0.06, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.42, 0.28)
	mesh_inst.material_override = mat
	return mesh_inst


func _make_stripe(x: float, color: Color, width: float) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 0.02, SEGMENT_LENGTH)
	mesh_inst.mesh = mesh
	mesh_inst.position = Vector3(x, 0.01, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.material_override = mat
	return mesh_inst


func _make_edge_line(x: float) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.1, 0.02, SEGMENT_LENGTH)
	mesh_inst.mesh = mesh
	mesh_inst.position = Vector3(x, 0.01, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 0.95)
	mesh_inst.material_override = mat
	return mesh_inst
