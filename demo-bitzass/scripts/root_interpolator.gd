@tool
class_name RootModifier
extends BodyPartInterpolator

@export var root_idx := 0

func _process_modification_with_delta(delta: float) -> void:
	if not anim_track_holder or Engine.is_editor_hint():
		return
	on_time_changed(anim_track_holder.time)
	interpolate_keyframes()

func interpolate_keyframes_in_time(time : float) -> Transform3D:
	if anim_track_holder.keyframes.size() == 0:
		return get_skeleton().get_bone_global_rest(0)
	var k_idxs := get_next_and_prev_keyframes_indices(time)
	
	var k1 := k_idxs[0]
	var k2 := k_idxs[1]
	
	var key_1 := anim_track_holder.keyframes[k1]
	var key_2 := anim_track_holder.keyframes[k2]
	
	return interpolate_root_in_time(time, key_1, key_2)
	
func interpolate_root_in_time(time : float, key_1 : Keyframe, key_2 : Keyframe) -> Transform3D:
	if anim_track_holder.keyframes.size() == 0:
		return get_skeleton().get_bone_global_rest(0)
	
	var animator_1 := key_1.animator as RootAnimator
	var animator_2 := key_2.animator as RootAnimator
	var t := get_t_from_keyframes(time, key_1, key_2)
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
	var pasted : bool = key.get_meta("was_pasted", false)
	if pasted:
		return
	var time := key.time
	var animator := key.animator as RootAnimator
	
	var stored : GizmoControllable
	if animator.gizmo:
		stored = animator.gizmo.controllable
		animator.gizmo.controllable = null
	
	var prev_key : Keyframe
	var next_key : Keyframe
	
	if key in anim_track_holder.keyframes:
		var this_idx := anim_track_holder.keyframes.find(key)
		
		if this_idx > 0:
			prev_key = anim_track_holder.keyframes[this_idx - 1]
		if this_idx < anim_track_holder.keyframes.size() - 1:
			next_key = anim_track_holder.keyframes[this_idx + 1]
		if this_idx <= 0:
			prev_key = next_key
		if this_idx >= anim_track_holder.keyframes.size() - 1:
			next_key = prev_key
	else:
		
		var ks := get_next_and_prev_keyframes_indices(time)
		prev_key = anim_track_holder.keyframes[ks[0]]
		next_key = anim_track_holder.keyframes[ks[1]]
	if not prev_key or not next_key:
		return
	animator.root.global_transform = interpolate_root_in_time(time, prev_key, next_key) * get_skeleton().get_bone_global_rest(root_idx).inverse() 
