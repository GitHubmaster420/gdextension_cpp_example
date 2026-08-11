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
	await get_skeleton().skeleton_updated
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
		var time := key.time
		
		var ks := get_next_and_prev_keyframes_indices(time)
		prev_key = anim_track_holder.keyframes[ks[0]]
		next_key = anim_track_holder.keyframes[ks[1]]
	var animator := key.animator as SpineAnimator
	animator.pelvis_rot_ease_curve = MyEaseInOut.new()
	animator.hip_rot_ease_curve = MyEaseInOut.new()
	animator.chest_rot_ease_curve = MyEaseInOut.new()
	if not prev_key or not next_key:
		return
	var t := get_t_from_keyframes(key.time, prev_key, next_key)
	
	var pelvis_b := interpolate_pelvis_basis(prev_key, next_key, t)
	var pelvis_l := interpolate_pelvis_loc(prev_key, next_key, t)
	var hip_b := interpolate_hip_basis(prev_key, next_key, t)
	var chest_b := interpolate_chest_basis(prev_key, next_key, t)
	
	animator.pelvis_root.transform = Transform3D(pelvis_b, pelvis_l)
	animator.hip_pose.basis = hip_b
	animator.chest_pose.basis = chest_b
	if not animator.gizmo:
		return
	if not animator.gizmo.controllable:
		return
	var stored := animator.gizmo.controllable
	
	animator.gizmo.controllable = null
	
	animator.gizmo.controllable = stored
	
func _process_modification_with_delta(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not anim_track_holder:
		return
	on_time_changed(anim_track_holder.time)
	
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
	
	(anim_track_holder.keyframes[prev_idx].animator as SpineAnimator).highlight()
	(anim_track_holder.keyframes[next_idx].animator as SpineAnimator).also_highlight()
	
	var k1 := anim_track_holder.keyframes[prev_idx]
	var k2 := anim_track_holder.keyframes[next_idx]
	
	var t := get_t_from_keyframes(time, k1, k2)
	
	var animator_1 := k1.animator as SpineAnimator
	var animator_2 := k2.animator as SpineAnimator

	var prev_1 := animator_1.pelvis_root.global_position
	var prev_2 := animator_2.pelvis_root.global_position
	
	var super_t_1 := animator_1.pelvis_root.transform
	var hip_b_1 := animator_1.hip_pose.basis.orthonormalized()
	var chest_b_1 := animator_1.chest_pose.basis.orthonormalized()
	
	var super_t_2 := animator_2.pelvis_root.transform
	var hip_b_2 := animator_2.hip_pose.basis.orthonormalized()
	var chest_b_2 := animator_2.chest_pose.basis.orthonormalized()
	
	var idx_0 := prev_keyframe_idx - 1
	
	var animator_0 : SpineAnimator
	
	if idx_0 > 0:
	
		animator_0 = anim_track_holder.keyframes[idx_0].animator
	else:
		animator_0 = animator_1
		animator_1.pelvis_g_tangent_auto_influence = 1
		animator_1.pelvis_r_tangent_auto_influence = 1
		animator_1.hip_r_tangent_auto_influence = 1
		animator_1.chest_r_auto_influence = 1
		
	if animator_1 == animator_2:
		pass
	else:
		if animator_1.pelvis_g_tangent_use_auto_tangent:
			var prev_pelvis_origin := animator_0.pelvis_root.global_position
			var next_pelvis_origin := prev_2
			
			animator_1.pelvis_g_tangent_vector = MyCurve3D.get_auto_tangent(prev_1, prev_pelvis_origin, next_pelvis_origin, (animator_1.pelvis_g_tangent_auto_influence + 1) / 2.0)
			
		if animator_1.pelvis_r_tangent_use_auto_tagent:
			var super_t_0 := animator_0.pelvis_root.transform
			animator_1.pelvis_r_tangent_vector = QuaternionExtender.get_auto_velocity_axis(super_t_1.basis, super_t_0.basis, super_t_2.basis, (animator_1.pelvis_r_tangent_auto_influence + 1) / 2.0)
		
		if animator_1.hips_r_tangent_use_auto_tagent:
			var hip_b_0 := animator_0.hip_pose.global_basis.orthonormalized()
			animator_1.hips_r_tangent_vector = QuaternionExtender.get_auto_velocity_axis(hip_b_1, hip_b_0, hip_b_2, (animator_1.hip_r_tangent_auto_influence + 1) / 2.0)
			
		if animator_1.chest_r_tangent_use_auto_tagent:
			var chest_b_0 := animator_0.chest_pose.global_basis.orthonormalized()
			animator_1.chest_r_tangent_vector = QuaternionExtender.get_auto_velocity_axis(chest_b_1, chest_b_0, chest_b_2, (animator_1.chest_r_auto_influence + 1) / 2.0)
			
	
	var idx_3 := next_keyframe_idx + 1
	
	var animator_3 : SpineAnimator
	
	if idx_3 < anim_track_holder.keyframes.size():
		animator_3 = anim_track_holder.keyframes[idx_3].animator
	else:
		animator_3 = animator_2
		animator_2.pelvis_g_tangent_auto_influence = -1
		animator_2.pelvis_r_tangent_auto_influence = -1
		animator_2.hip_r_tangent_auto_influence = -1
		animator_2.pelvis_r_tangent_auto_influence = -1
			
	if animator_1 == animator_2:
		pass
	else:
		if animator_2.pelvis_g_tangent_use_auto_tangent:
			var prev_pelvis := animator_1.current_transforms[0]
			var prev_pelvis_origin := prev_pelvis.origin
			var next_pelvis := animator_3.current_transforms[0]
			var next_pelvis_origin := next_pelvis.origin
			animator_2.pelvis_g_tangent_vector = MyCurve3D.get_auto_tangent(prev_2, prev_pelvis_origin, next_pelvis_origin, (animator_2.pelvis_g_tangent_auto_influence + 1))
		if animator_2.pelvis_r_tangent_use_auto_tagent:
			
			var super_t_3 := animator_3.pelvis_root.global_transform
			animator_2.pelvis_r_tangent_vector = QuaternionExtender.get_auto_velocity_axis(super_t_2.basis, super_t_1.basis, super_t_3.basis, (animator_2.pelvis_r_tangent_auto_influence + 1) / 2.0)
		if animator_2.hips_r_tangent_use_auto_tagent:
			var hip_b_3 := animator_3.hip_pose.global_basis.orthonormalized()
			animator_2.hips_r_tangent_vector = QuaternionExtender.get_auto_velocity_axis(hip_b_2, hip_b_1, hip_b_3, (animator_2.hip_r_tangent_auto_influence + 1) / 2.0)
		if animator_2.chest_r_tangent_use_auto_tagent:
			var chest_b_3 := animator_3.chest_pose.global_basis.orthonormalized()
			animator_2.chest_r_tangent_vector = QuaternionExtender.get_auto_velocity_axis(chest_b_2, chest_b_1, chest_b_3, (animator_2.chest_r_auto_influence + 1) / 2.0)
	
	var super_t := interpolate_pelvis_basis(k1, k2, t)
	var hip_b := interpolate_hip_basis(k1, k2, t)
	var chest_b := interpolate_chest_basis(k1, k2, t)
	
	var super_t_location := interpolate_pelvis_loc(k1, k2, t)
	#
	#print("origin 1: ", super_t_1.origin, " origin 2: ", super_t_2.origin, " super t loc: ", super_t_location)
	#
	var super_t_transform := Transform3D(super_t, super_t_location)
	
	var transforms := animator_1.get_transforms_from_drivers(root_modifier.interpolate_keyframes_in_time(time), super_t_transform, hip_b, chest_b)
	
	return transforms
	
func interpolate_pelvis_basis(key_1 : Keyframe, key_2 : Keyframe, t : float) -> Quaternion:
	var animator_1 := key_1.animator as SpineAnimator
	var animator_2 := key_2.animator as SpineAnimator
	var b_1 := animator_1.pelvis_root.basis.get_rotation_quaternion()
	var b_2 := animator_2.pelvis_root.basis.get_rotation_quaternion()
	var pelvis_r_velocity_vector_1 := animator_1.pelvis_r_tangent_vector
	var pelvis_r_velocity_vector_2 := animator_2.pelvis_r_tangent_vector
	
	var super_t := QuaternionExtender.my_quat_interpolate(b_1, pelvis_r_velocity_vector_1, animator_1.pelvis_r_vel, b_2, pelvis_r_velocity_vector_2, animator_2.pelvis_r_vel, t, key_2.time - key_1.time, animator_2.pelvis_rot_ease_curve.baked_points)

	return super_t

func interpolate_hip_basis(key_1 : Keyframe, key_2 : Keyframe, t : float) -> Quaternion:
	var animator_1 := key_1.animator as SpineAnimator
	var animator_2 := key_2.animator as SpineAnimator
	var b_1 := animator_1.hip_pose.basis.get_rotation_quaternion()
	var b_2 := animator_2.hip_pose.basis.get_rotation_quaternion()
	var hip_r_velocity_vector_1 := animator_1.hips_r_tangent_vector
	var hip_r_velocity_vector_2 := animator_2.pelvis_r_tangent_vector
	
	var super_t := QuaternionExtender.my_quat_interpolate(b_1, hip_r_velocity_vector_1, animator_1.hip_r_vel, b_2, hip_r_velocity_vector_2, animator_2.hip_r_vel, t, key_2.time - key_1.time, animator_2.hip_rot_ease_curve.baked_points)

	return super_t

func interpolate_chest_basis(key_1 : Keyframe, key_2 : Keyframe, t : float) -> Quaternion:
	var animator_1 := key_1.animator as SpineAnimator
	var animator_2 := key_2.animator as SpineAnimator
	var b_1 := animator_1.chest_pose.basis.get_rotation_quaternion()
	var b_2 := animator_2.chest_pose.basis.get_rotation_quaternion()
	var chest_r_velocity_vector_1 := animator_1.chest_r_tangent_vector
	var chest_r_velocity_vector_2 := animator_2.pelvis_r_tangent_vector
	
	var super_t := QuaternionExtender.my_quat_interpolate(b_1, chest_r_velocity_vector_1, animator_1.chest_r_vel, b_2, chest_r_velocity_vector_2, animator_2.chest_r_vel, t, key_2.time - key_1.time, animator_2.chest_rot_ease_curve.baked_points)

	return super_t

func interpolate_pelvis_loc(key_1 : Keyframe, key_2 : Keyframe, t : float) -> Vector3:
	var animator_1 := key_1.animator as SpineAnimator
	var animator_2 := key_2.animator as SpineAnimator
	
	var loc_1 := animator_1.pelvis_root.position
	var loc_2 := animator_2.pelvis_root.position
	
	var root_1_b := animator_1.root.basis
	var root_2_b := animator_2.root.basis
	
	var velocity_vector_1 := root_1_b.inverse() * (animator_1.pelvis_g_tangent_vector * animator_1.pelvis_g_vel)
	var velocity_vector_2 := root_2_b.inverse() * (animator_2.pelvis_g_tangent_vector * animator_2.pelvis_g_vel)
	
	var loc := MyCurve3D.interpolate(loc_1, velocity_vector_1, loc_2, velocity_vector_2, t, key_2.time - key_1.time, animator_2.pelvis_loc_ease_curve.baked_points)
	
	return loc

func interpolate_keyframes():
	if anim_track_holder.keyframes.size() == 0:
		return
	
	var transforms := interpolate_keyframes_in_time(anim_track_holder.time)
	
	#print("origin: ", transforms[0].origin)
	
	get_skeleton().set_bone_pose_position(spine_based_idx, (root_modifier.interpolate_keyframes_in_time(anim_track_holder.time).inverse())* transforms[0].origin)
	#
	var prev := transforms[0].basis.get_rotation_quaternion()
	get_skeleton().set_bone_pose_rotation(spine_based_idx, root_modifier.interpolate_keyframes_in_time(anim_track_holder.time).basis.inverse().get_rotation_quaternion() * (prev as Quaternion))
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
	
