@tool
extends BodyPartInterpolator
class_name HeadInterpolator

@export var head_name : String:
	set(v):
		head_name = v
		if not get_skeleton():
			return
		head_idx = get_skeleton().find_bone(head_name)
@export var neck_name : String:
	set(v):
		neck_name = v
		if not get_skeleton():
			return
		neck_idx = get_skeleton().find_bone(neck_name)

@export var head_idx : int
@export var neck_idx : int

func _ready() -> void:
	super()
	head_name = head_name
	neck_name = neck_name

func _validate_property(property: Dictionary) -> void:
	if property.name == "head_name" or property.name == "neck_name":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()

func _process_modification_with_delta(delta: float) -> void:
	on_time_changed(current_time)
	interpolate_keyframes()

func interpolate_keyframes():
	if anim_track_holder.keyframes.size() == 0:
		return
	var animator_1 := prev_keyframe.animator as HeadAnimator
	var animator_2 := next_keyframe.animator as HeadAnimator
	
	var t := get_t_from_keyframes(current_time)
	
	var neck_b := animator_1.neck.basis.slerp(animator_2.neck.basis, t)
	var head_b := animator_2.head.basis.slerp(animator_2.head.basis, t)
	
	get_skeleton().set_bone_pose_rotation(neck_idx, neck_b)
	get_skeleton().set_bone_pose_rotation(head_idx, head_b)

func on_keyframe_added(key : Keyframe):
	await get_skeleton().skeleton_updated
	var animator := key.animator as HeadAnimator
	
	animator.chest.global_transform = get_skeleton().get_bone_global_pose(get_skeleton().get_bone_parent(neck_idx))
	animator.neck.global_transform = get_skeleton().get_bone_global_pose(neck_idx)
	animator.head.global_transform = get_skeleton().get_bone_global_pose(head_idx)
	
