@tool
class_name RootModifier
extends BodyPartInterpolator

@export var root_idx := 0

func _process_modification_with_delta(delta: float) -> void:
	if not anim_track_holder:
		return
	on_time_changed(anim_track_holder.time)
	interpolate_keyframes()

func interpolate_keyframes_in_time(time : float) -> Transform3D:
	if anim_track_holder.keyframes.size() == 0:
		return get_skeleton().get_bone_global_rest(0)
	var k_idxs := get_next_and_prev_keyframes_indices(time)
	
	var k1 := k_idxs[0]
	var k2 := k_idxs[1]
	
	var animator_1 := anim_track_holder.keyframes[k1].animator as RootAnimator
	var animator_2 := anim_track_holder.keyframes[k2].animator as RootAnimator
	var t := get_t_from_keyframes(time, anim_track_holder.keyframes[k1], anim_track_holder.keyframes[k2])
	var dur := next_keyframe.time - prev_keyframe.time
	var rot := QuaternionExtender.my_quat_interpolate(animator_1.root.basis.get_rotation_quaternion(), animator_1.angular_velocity_tangent, animator_1.angular_velocity_amount,
	animator_2.root.basis.get_rotation_quaternion(), animator_2.angular_velocity_tangent, animator_2.angular_velocity_amount, t, dur, animator_2.rot_ease_curve.baked_points)
	
	var loc := MyCurve3D.interpolate(animator_1.root.global_position, animator_1.velocity_tangent_vector, animator_2.root.global_position, animator_2.velocity_tangent_vector, t, dur, animator_2.loc_ease_curve.baked_points)	
	
	return Transform3D(rot, loc) * get_skeleton().get_bone_global_rest(root_idx)
	

func interpolate_keyframes():
	if anim_track_holder.keyframes.size() == 0:
		return
	var trns := interpolate_keyframes_in_time(anim_track_holder.time)
	get_skeleton().set_bone_pose(0, trns)

func on_keyframe_added(key : Keyframe):
	pass
