@tool
extends BodyPartInterpolator
class_name SpineBoneModifier

@export var root_modifier : RootModifier

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
	var animator := key.animator as SpineAnimator
	animator.pelvis_rot_ease_curve = MyEaseInOut.new()
	animator.hip_rot_ease_curve = MyEaseInOut.new()
	animator.chest_rot_ease_curve = MyEaseInOut.new()

func _process_modification_with_delta(delta: float) -> void:
	if not anim_track_holder:
		return
	on_time_changed(current_time)
	
	if anim_track_holder.keyframes.size() == 0:
		return
	
	var a1 := prev_keyframe.animator as SpineAnimator
	var a2 := next_keyframe.animator as SpineAnimator
	
	a1.root.global_transform = root_modifier.interpolate_keyframes_in_time(prev_keyframe.time)
	a2.root.global_transform = root_modifier.interpolate_keyframes_in_time(next_keyframe.time)
	
	interpolate_keyframes()

func interpolate_keyframes_in_time(time : float) -> Array[Transform3D]:
	if anim_track_holder.keyframes.size() == 0:
		return [get_skeleton().get_bone_global_rest(1), get_skeleton().get_bone_global_rest(2), get_skeleton().get_bone_global_rest(3), get_skeleton().get_bone_global_rest(4)]
	var idxs := get_next_and_prev_keyframes_indices(time)
	var prev_idx := idxs[0]
	var next_idx := idxs[1]
	
	var t := get_t_from_keyframes(time)
	
	var k1 := anim_track_holder.keyframes[prev_idx]
	var k2 := anim_track_holder.keyframes[next_idx]
	
	var animator_1 := k1.animator as SpineAnimator
	var animator_2 := k2.animator as SpineAnimator

	var prev_1 := animator_1.pelvis_root.global_position
	var prev_2 := animator_2.pelvis_root.global_position
	var velocity_vector_1 : Vector3
	
	var super_t_1 := animator_1.pelvis_root.global_transform
	var hip_b_1 := animator_1.hip_pose.global_basis.orthonormalized()
	var chest_b_1 := animator_1.chest_pose.global_basis.orthonormalized()
	
	var super_t_2 := animator_2.pelvis_root.global_transform
	var hip_b_2 := animator_2.hip_pose.global_basis.orthonormalized()
	var chest_b_2 := animator_2.chest_pose.global_basis.orthonormalized()
	
	var pelvis_r_velocity_vector_1 : Vector3
	var hip_r_velocity_vector_1 : Vector3
	var chest_r_velocity_vector_1 : Vector3
	var pelvis_r_velocity_vector_2 : Vector3
	var hip_r_velocity_vector_2 : Vector3
	var chest_r_velocity_vector_2 : Vector3

	
	if animator_1.use_auto_tangent:
		
		if animator_1 == animator_2:
			velocity_vector_1 = Vector3.ZERO
		else:
			var _prev_keyframe_idx : int
			if animator_1 == anim_track_holder.keyframes[0].animator:
				animator_1.pelvis_g_tangent_auto_influence = 1
				_prev_keyframe_idx = 0
			else:
				_prev_keyframe_idx = anim_track_holder.keyframes.find(animator_1.get_parent()) - 1
			var animator_0 := anim_track_holder.keyframes[_prev_keyframe_idx].animator as SpineAnimator
			var prev_pelvis_origin := animator_0.pelvis_root.global_position
			var next_pelvis_origin := prev_2
			
			velocity_vector_1 = MyCurve3D.get_auto_tangent(prev_1, prev_pelvis_origin, next_pelvis_origin, (animator_1.pelvis_g_tangent_auto_influence + 1) / 2.0)
			
			var super_t_0 := animator_0.pelvis_root.global_transform
			var hip_b_0 := animator_0.hip_pose.global_basis.orthonormalized()
			var chest_b_0 := animator_0.chest_pose.global_basis.orthonormalized()
			
			pelvis_r_velocity_vector_1 = QuaternionExtender.get_auto_velocity_axis(super_t_1.basis, super_t_0.basis, super_t_2.basis, (animator_1.pelvis_r_tangent_auto_influence + 1) / 2.0)
			hip_r_velocity_vector_1 = QuaternionExtender.get_auto_velocity_axis(hip_b_1, hip_b_0, hip_b_2, (animator_1.hip_r_tangent_auto_influence + 1) / 2.0)
			chest_r_velocity_vector_1 = QuaternionExtender.get_auto_velocity_axis(chest_b_1, chest_b_0, chest_b_2, (animator_1.chest_r_auto_influence + 1) / 2.0)
			
	var velocity_vector_2 : Vector3
	if animator_2.use_auto_tangent:
		
		if animator_1 == animator_2:
			velocity_vector_2 = Vector3.ZERO
		else:
			var _next_keyframe_idx : int
			if animator_2 == anim_track_holder.keyframes[-1].animator:
				animator_2.pelvis_g_tangent_auto_influence = -1
				_next_keyframe_idx = -1
			else:
				_next_keyframe_idx = anim_track_holder.keyframes.find(animator_2.get_parent()) + 1
			var animator_3 := anim_track_holder.keyframes[_next_keyframe_idx].animator as SpineAnimator
			var prev_pelvis := animator_1.current_transforms[0]
			var prev_pelvis_origin := prev_pelvis.origin
			var next_pelvis := animator_3.current_transforms[0]
			var next_pelvis_origin := next_pelvis.origin
			velocity_vector_2 = MyCurve3D.get_auto_tangent(prev_2, prev_pelvis_origin, next_pelvis_origin, (animator_2.pelvis_g_tangent_auto_influence + 1))
			
			var super_t_3 := animator_3.pelvis_root.global_transform
			var hip_b_3 := animator_3.hip_pose.global_basis.orthonormalized()
			var chest_b_3 := animator_3.chest_pose.global_basis.orthonormalized()
			
			pelvis_r_velocity_vector_2 = QuaternionExtender.get_auto_velocity_axis(super_t_2.basis, super_t_1.basis, super_t_3.basis, (animator_2.pelvis_r_tangent_auto_influence + 1) / 2.0)
			hip_r_velocity_vector_2 = QuaternionExtender.get_auto_velocity_axis(hip_b_2, hip_b_1, hip_b_3, (animator_2.hip_r_tangent_auto_influence + 1) / 2.0)
			chest_r_velocity_vector_2 = QuaternionExtender.get_auto_velocity_axis(chest_b_2, chest_b_1, chest_b_3, (animator_2.chest_r_auto_influence + 1) / 2.0)
	
	
	
	var super_t := QuaternionExtender.my_quat_interpolate(super_t_1.basis, super_t_1.basis * pelvis_r_velocity_vector_1, 1, animator_1.pelvis_r_vel, super_t_2.basis, super_t_2.basis * pelvis_r_velocity_vector_2, 1, animator_2.pelvis_r_vel, t, k2.time - k1.time, animator_2.pelvis_rot_ease_curve.baked_points)
	var hip_b := QuaternionExtender.my_quat_interpolate(hip_b_1, hip_b_1 * hip_r_velocity_vector_1, 1, animator_1.hip_r_vel, hip_b_2, hip_b_2 * hip_r_velocity_vector_2, 1, animator_2.hip_r_vel, t, k2.time - k1.time, animator_2.hip_rot_ease_curve.baked_points)
	var chest_b := QuaternionExtender.my_quat_interpolate(chest_b_1, chest_b_1 * chest_r_velocity_vector_1, 1, animator_1.chest_r_vel, chest_b_2, chest_b_2 * chest_r_velocity_vector_2, 1, animator_2.chest_r_vel, t, k2.time - k1.time, animator_2.chest_rot_ease_curve.baked_points)
	
	var pelvis_t := super_t * hip_b * (animator_1.pelvis_final.basis.get_rotation_quaternion())
	
	var super_t_location := super_t_1.origin#MyCurve3D.interpolate(super_t_1.origin, velocity_vector_1, super_t_2.origin, velocity_vector_2, t, k2.time - k1.time)
	
	var super_t_transform := Transform3D(super_t, super_t_location)
	
	var transforms := animator_1.get_transforms_from_drivers(super_t_transform, pelvis_t, hip_b, chest_b)
	
	return transforms
	
	

func interpolate_keyframes():
	if anim_track_holder.keyframes.size() == 0:
		return
	
	var transforms := interpolate_keyframes_in_time(current_time)
	
	get_skeleton().set_bone_pose_position(spine_based_idx, get_skeleton().get_bone_global_rest(0).inverse() * transforms[0].origin)
	#
	var prev := transforms[0].basis.get_rotation_quaternion()
	get_skeleton().set_bone_pose_rotation(spine_based_idx, (get_skeleton().get_bone_rest(0).basis.inverse() as Quaternion) * (prev as Quaternion))
	for i in range(1, transforms.size(), 1):
		get_skeleton().set_bone_pose_rotation(spine_based_idx + i, prev.inverse() * (transforms[i].basis as Quaternion))
		prev = transforms[i].basis
	
	#
	#get_skeleton().set_bone_pose_rotation(spine_based_idx,get_skeleton().get_bone_pose_rotation(0).inverse() * (prev_1.basis.slerp(prev_2.basis, t) as Quaternion))
	#for i in range(1, animator_1.current_transforms.size(), 1):
		#var b1 := prev_1.basis.inverse() * animator_1.current_transforms[i].basis
		#var b2 := prev_2.basis.inverse() * animator_2.current_transforms[i].basis
		#get_skeleton().set_bone_pose_rotation(spine_based_idx + i, b1.slerp(b2, t))
		#prev_1 = animator_1.current_transforms[i]
		#prev_2 = animator_2.current_transforms[i]

func interpolate_pelvis_in_time(time : float) -> Transform3D:
	if anim_track_holder.keyframes.size() == 0:
		return get_skeleton().get_bone_global_rest(spine_based_idx)
	var transforms := interpolate_keyframes_in_time(time)
	var pelvis_tr := transforms[0]
	return pelvis_tr

func interpolate_chest_in_time(time : float) -> Transform3D:
	if anim_track_holder.keyframes.size() == 0:
		return get_skeleton().get_bone_global_rest(chain_end_idx)
	var transforms := interpolate_keyframes_in_time(time)
	var chest_tr := transforms[-1]
	return chest_tr
	
