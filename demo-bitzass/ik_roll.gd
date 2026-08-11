extends Marker3D
class_name IkRoll

@export var target_object : Marker3D

func _process(delta: float) -> void:
	return
	global_basis.y = global_position.direction_to(target_object.global_position)
	global_basis.x = global_basis.y.cross(global_basis.z).normalized()
	global_basis.z = global_basis.x.cross(global_basis.y).normalized()
	global_basis.x = global_basis.y.cross(global_basis.z).normalized()
	
