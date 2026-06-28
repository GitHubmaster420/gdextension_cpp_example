@tool
class_name RootModifier
extends BodyPartInterpolator

@export var root_idx := 0

func _process_modification_with_delta(delta: float) -> void:
	if not anim_track_holder:
		return
	on_time_changed(current_time)
	interpolate_keyframes()

func interpolate_keyframes_in_time(time : float) -> Transform3D:
	if anim_track_holder.keyframes.size() == 0:
		return get_skeleton().get_bone_global_rest(0)
	var k_idxs := get_next_and_prev_keyframes_indices(time)
	
	var k1 := k_idxs[0]
	var k2 := k_idxs[1]
	
	var animator_1 := prev_keyframe.animator as RootAnimator
	var animator_2 := next_keyframe.animator as RootAnimator
	
	var t := get_t_from_keyframes(time)
	
	return animator_1.root.global_transform.interpolate_with(animator_2.root.global_transform, t) * get_skeleton().get_bone_global_rest(0)
	

func interpolate_keyframes():
	if anim_track_holder.keyframes.size() == 0:
		return
	var trns := interpolate_keyframes_in_time(current_time)
	get_skeleton().set_bone_pose(0, trns)

func on_keyframe_added(key : Keyframe):
	pass
