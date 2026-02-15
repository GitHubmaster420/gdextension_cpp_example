@tool
extends SkeletonModifier3D
class_name IncrementalRotation

@export_enum("string") var start_bone : String
@export_enum("string") var end_bone : String

func _validate_property(property: Dictionary) -> void:
	if property.name == "start_bone" or property.name == "end_bone":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()

@export var origin : Node3D
@export var target : Node3D

@export var origin_offset : Basis
@export var target_offset : Basis

@export_tool_button("set offset as current") var s = set_current_rot_as_offset

func set_current_rot_as_offset():
	origin_offset = origin.global_basis
	target_offset = target.global_basis


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton : Skeleton3D = get_skeleton()
	var id_start := skeleton.find_bone(start_bone)
	
	var id_end := skeleton.find_bone(end_bone)
	

	var sign := signi(id_end - id_start)
	
	var size := absi(id_start - id_end)
	
	var skel_inv := skeleton.global_transform.affine_inverse()

	var origin_xform := skel_inv * origin.global_transform * Transform3D(origin_offset, Vector3.ZERO).affine_inverse()
	var target_xform := skel_inv * target.global_transform * Transform3D(target_offset, Vector3.ZERO).affine_inverse()
	
	for id in range(id_start, id_end + sign, sign):
		var t : float
		if sign > 0:
			t = float(id - id_start) / float(size) #if id >= id_start, works
			t = 1.0 - t #stupid
		else:
			t = float(id - id_end) / float(size)
			t = 1.0 - t
		#
		#skeleton.set_bone_global_pose(id, Transform3D(skeleton.global_basis.inverse() * (origin.global_basis * origin_offset.inverse()).slerp(target.global_basis * target_offset.inverse(), t) * skeleton.get_bone_global_rest(id).basis ,skeleton.get_bone_global_pose(id).origin))
		var blended_basis := origin_xform.basis.slerp(target_xform.basis, t)
		var rest_basis := skeleton.get_bone_global_rest(id).basis
		var final_basis := blended_basis * rest_basis
		
		
		var pose := skeleton.get_bone_global_pose(id)
		pose.basis = final_basis
		skeleton.set_bone_global_pose(id, pose)
