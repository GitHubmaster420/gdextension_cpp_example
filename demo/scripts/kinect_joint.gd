@tool
extends MeshInstance3D
class_name KinectJoint

@export var _skeleton : Skeleton3D

@export_enum("bone") var bone : String

@export var next_node : Node3D

@export_tool_button("look at next") var l = look_at_next

@export var target_node : Node3D

@export var forward_dir := Vector3.FORWARD

func _validate_property(property: Dictionary) -> void:
	if property.name == "bone":
		if not _skeleton:
			return
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = _skeleton.get_concatenated_bone_names()

func copy_position():
	await _skeleton.skeleton_updated
	global_position = (_skeleton.global_transform * _skeleton.get_bone_global_pose(_skeleton.find_bone(bone))).origin 

func look_at_next():
	global_transform = _y_look_at(global_transform, next_node.global_position)

func _y_look_at(from: Transform3D, target: Vector3) -> Transform3D:
	var t_v: Vector3 = target - from.origin
	var v_y: Vector3 = t_v.normalized()
	var z_dir : Vector3
	if not target_node:
		z_dir = forward_dir
	else:
		z_dir = ((from.origin + target) / 2.0) - target_node.global_position # This makes -z point towards target, no idea why
	var v_x := v_y.cross(z_dir)
	v_x = v_x.normalized()
	var v_z = v_x.cross(v_y)
	from.basis = Basis(v_x, v_y, v_z)
	return from

func _physics_process(delta: float) -> void:
	if next_node:
		look_at_next()
