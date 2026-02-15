@tool
extends SkeletonModifier3D
class_name CopyRotY

@export_enum("string") var bone : String

@export var target : Node3D

@export var offset : Basis

@export_tool_button("set offset as current") var s = set_current_rot_as_offset

func set_current_rot_as_offset():
	offset = target.global_basis

func _validate_property(property: Dictionary) -> void:
	if property.name == "bone":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()



func _process_modification_with_delta(delta: float) -> void:
	var skeleton : Skeleton3D = get_skeleton()
	var id := skeleton.find_bone(bone)
	
	if not target:
		return
	var reference_basis := (target.global_basis * offset.inverse())
	# basis in world space, -z points forward
	var reference_z := reference_basis.z
	var up := Vector3.UP
	var _x = -reference_z.cross(up).normalized()
	var _z = -up.cross(_x).normalized()
	var _y = up
	var _basis_rotated_y := Basis(_x, _y, _z)
	skeleton.set_bone_global_pose(id, Transform3D((skeleton.global_basis.inverse() * _basis_rotated_y * skeleton.get_bone_global_rest(id).basis).orthonormalized(), skeleton.get_bone_global_pose(id).origin))
	
	
