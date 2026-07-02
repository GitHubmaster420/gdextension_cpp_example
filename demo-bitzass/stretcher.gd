@tool
extends MeshInstance3D
class_name Stretcher

@export var start_stretch : Marker3D
@export var end_stretch : Marker3D

func _init() -> void:
	mesh = CapsuleMesh.new()
	mesh.radius = 0.05
	top_level = true

func _process(delta: float) -> void:
	if not (start_stretch and end_stretch):
		return
	stretch_to_target()

func stretch_to_target():
	var start_pos := start_stretch.global_position
	var end_pos := end_stretch.global_position
	
	global_position = (start_pos + end_pos) / 2.0
	if mesh is not CapsuleMesh:
		mesh = CapsuleMesh.new()
		mesh.radius = 0.05
	if not is_visible_in_tree():
		return
	(mesh as CapsuleMesh).height = start_pos.distance_to(end_pos)
	global_basis.y = start_pos.direction_to(end_pos)
	if not global_basis.y:
		global_basis = Basis.IDENTITY
		return
	var temp_z := Vector3.FORWARD if absf(global_basis.y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	global_basis.x = global_basis.y.cross(temp_z).normalized()
	global_basis.z = global_basis.x.cross(global_basis.y).normalized()
