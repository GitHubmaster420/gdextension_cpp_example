@tool
extends BodyPartInterpolator
class_name SpineBoneModifier

@export var spine_base_name : String:
	set(v):
		spine_base_name = v
		if not is_node_ready():
			return
		spine_based_idx = get_skeleton().find_bone(spine_base_name)
@export var spine_based_idx : int
@export var chain_end_name : String:
	set(v):
		chain_end_name = v
		if not is_node_ready():
			return
		chain_end_idx = get_skeleton().find_bone(chain_end_name)

@export var chain_end_idx : int



func _ready() -> void:
	super()
	spine_base_name = spine_base_name
	chain_end_name = chain_end_name

func _validate_property(property: Dictionary) -> void:
	if property.name == "spine_base_name" or property.name == "chain_end_name":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()

func on_keyframe_added(key : Keyframe):
	pass

func _process_modification_with_delta(delta: float) -> void:
	if not anim_track_holder:
		return
	interpolate_keyframes()

func interpolate_keyframes():
	if anim_track_holder.keyframes.size() == 0:
		return
	if prev_keyframe_idx < 0 or next_keyframe_idx < 0:
		prev_keyframe_idx = 0
		next_keyframe_idx = 0

	var t : float = get_t_from_keyframes(anim_track_holder.time)
	
	
	var animator_1 := prev_keyframe.animator as SpineAnimator
	var animator_2 := next_keyframe.animator as SpineAnimator
	
	var prev_1 := animator_1.current_transforms[0]
	var prev_2 := animator_2.current_transforms[0]
	get_skeleton().set_bone_global_pose(spine_based_idx, prev_1.interpolate_with(prev_2, t))
	for i in range(1, animator_1.current_transforms.size(), 1):
		var b1 := prev_1.basis.inverse() * animator_1.current_transforms[i].basis
		var b2 := prev_2.basis.inverse() * animator_2.current_transforms[i].basis
		get_skeleton().set_bone_pose_rotation(spine_based_idx + i, b1.slerp(b2, t))
		prev_1 = animator_1.current_transforms[i]
		prev_2 = animator_2.current_transforms[i]

func interpolate_pelvis_in_time(time : float) -> Transform3D:
	if anim_track_holder.keyframes.size() == 0:
		return get_skeleton().get_bone_global_rest(spine_based_idx)
	var indices := get_next_and_prev_keyframes_indices(time)
	
	var k1 := anim_track_holder.keyframes[indices[0]]
	var k2 := anim_track_holder.keyframes[indices[1]]
	var t := get_t_from_keyframes(time, k1, k2)
	
	var animator_1 := k1.animator as SpineAnimator
	var animator_2 := k2.animator as SpineAnimator
	
	
	var pelvis_tr := animator_1.current_transforms[0].interpolate_with(animator_2.current_transforms[0], t)
	return pelvis_tr

func interpolate_chest_in_time(time : float) -> Transform3D:
	if anim_track_holder.keyframes.size() == 0:
		return get_skeleton().get_bone_global_rest(chain_end_idx)
	var indices := get_next_and_prev_keyframes_indices(time)
	
	var k1 := anim_track_holder.keyframes[indices[0]]
	var k2 := anim_track_holder.keyframes[indices[1]]
	var t := get_t_from_keyframes(time, k1, k2)
	
	var animator_1 := k1.animator as SpineAnimator
	var animator_2 := k2.animator as SpineAnimator
	
	
	var chest_tr := animator_1.current_transforms[-1].interpolate_with(animator_2.current_transforms[-1], t)
	return chest_tr
	
