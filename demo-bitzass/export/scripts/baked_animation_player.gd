@tool
extends SkeletonModifier3D
class_name BakedAnimationPlayer

enum BallHitPart{
	RIGHT_FOOT,
	LEFT_FOOT,
	RIGHT_HAND,
	LEFT_HAND,
	SPINE,
	HEAD
	
}

@export var foot_contact_parent := BakedFootAnimator.Parent.PREV_ANIMATOR

@export_tool_button("add contact to keyframe") var cb := create_ball_contact_keyframe

func create_ball_contact_keyframe():
	var h : BakedTrackHolder
	match ball_hit_part:
		BallHitPart.RIGHT_FOOT:
			h = baked_animation.right_foot_track_holder
			var animator := h.baked_animators[ball_hit_keyframe_idx]
			match ball_contact_point:
				"foot":
					animator.hit_idx = 0
					animator.hits_ball = true
					var next_animator : BakedFootAnimator
					
					if ball_hit_keyframe_idx <= h.baked_animators.size():
						next_animator = h.baked_animators[ball_hit_keyframe_idx + 1]
						next_animator.parent = foot_contact_parent

@export var ball_hit_keyframe_idx : int:
	set(v):
		ball_hit_keyframe_idx = v
		var h : BakedTrackHolder
		match ball_hit_part:
			BallHitPart.RIGHT_FOOT:
				h = baked_animation.right_foot_track_holder
		ball_hit_keyframe_idx = clampi(ball_hit_keyframe_idx, 0, h.keyframe_times.size() - 1)
		ball_hit_keyframe_time = h.keyframe_times[ball_hit_keyframe_idx]
@export var ball_hit_part : BallHitPart:
	set(v):
		ball_hit_part = BallHitPart.RIGHT_FOOT # TODO: make editable
		match ball_hit_part:
			BallHitPart.RIGHT_FOOT:
				ball_contact_point = "foot"
@export var ball_hit_keyframe_time : float

@export var ball_contact_point : String:
	set(v):
		ball_contact_point = "foot" #TODO: make editable

var prev_ball_pos : Vector3
var prev_ball_tangent : Vector3

@export var ball_mesh : MeshInstance3D
@export var ball : AnimSimulatorBall

@export_tool_button("snap ball") var sp := snap_ball

@export var playing := false

@export var time := 0.0

@export_range(0.0, 2.0, 0.01) var max_time := 0.7

@export var baked_animation : BakedAnimation

@export var right_thigh_idx : int
@export var right_shin_idx : int
@export var right_foot_idx : int

@export var right_thigh_name : String:
	set(v):
		right_thigh_name = v
		if not is_node_ready():
			return
		right_thigh_idx = get_skeleton().find_bone(v)
@export var right_shin_name : String:
	set(v):
		right_shin_name = v
		if not is_node_ready():
			return
		right_shin_idx = get_skeleton().find_bone(v)
@export var right_foot_name : String:
	set(v):
		right_foot_name = v
		if not is_node_ready():
			return
		right_foot_idx = get_skeleton().find_bone(v)
		
		
@export var left_thigh_idx : int
@export var left_shin_idx : int
@export var left_foot_idx : int

@export var left_thigh_name : String:
	set(v):
		left_thigh_name = v
		if not is_node_ready():
			return
		left_thigh_idx = get_skeleton().find_bone(v)
@export var left_shin_name : String:
	set(v):
		left_shin_name = v
		if not is_node_ready():
			return
		left_shin_idx = get_skeleton().find_bone(v)
@export var left_foot_name : String:
	set(v):
		left_foot_name = v
		if not is_node_ready():
			return
		left_foot_idx = get_skeleton().find_bone(v)

@export var right_shoulder_idx : int
@export var right_up_arm_idx : int
@export var right_fore_arm_idx : int
@export var right_hand_idx : int

@export var right_shoulder_name : String:
	set(v):
		right_shoulder_name = v
		if not is_node_ready():
			return
		right_shoulder_idx = get_skeleton().find_bone(v)
@export var right_up_arm_name : String:
	set(v):
		right_up_arm_name = v
		if not is_node_ready():
			return
		right_up_arm_idx = get_skeleton().find_bone(v)
@export var right_fore_arm_name : String:
	set(v):
		right_fore_arm_name = v
		if not is_node_ready():
			return
		right_fore_arm_idx = get_skeleton().find_bone(v)
@export var right_hand_name : String:
	set(v):
		right_hand_name = v
		if not is_node_ready():
			return
		right_hand_idx = get_skeleton().find_bone(v)
		

@export var left_shoulder_idx : int
@export var left_up_arm_idx : int
@export var left_fore_arm_idx : int
@export var left_hand_idx : int

@export var left_shoulder_name : String:
	set(v):
		left_shoulder_name = v
		if not is_node_ready():
			return
		left_shoulder_idx = get_skeleton().find_bone(v)
@export var left_up_arm_name : String:
	set(v):
		left_up_arm_name = v
		if not is_node_ready():
			return
		left_up_arm_idx = get_skeleton().find_bone(v)
@export var left_fore_arm_name : String:
	set(v):
		left_fore_arm_name = v
		if not is_node_ready():
			return
		left_fore_arm_idx = get_skeleton().find_bone(v)
@export var left_hand_name : String:
	set(v):
		left_hand_name = v
		if not is_node_ready():
			return
		left_hand_idx = get_skeleton().find_bone(v)



@export var spine_start_idx : int
@export var spine_start_name : String:
	set(v):
		spine_start_name = v
		if not is_node_ready():
			return
		spine_start_idx = get_skeleton().find_bone(v)


@export var hip_start_idx : int
@export var hip_start_name : String:
	set(v):
		hip_start_name = v
		if not is_node_ready():
			return
		hip_start_idx = get_skeleton().find_bone(v)


@export var chest_start_idx : int
@export var chest_start_name : String:
	set(v):
		chest_start_name = v
		if not is_node_ready():
			return
		chest_start_idx = get_skeleton().find_bone(v)

@export var neck_start_idx : int
@export var neck_start_name : String:
	set(v):
		neck_start_name = v
		if not is_node_ready():
			return
		neck_start_idx = get_skeleton().find_bone(v)

@export var head_start_idx : int
@export var head_start_name : String:
	set(v):
		head_start_name = v
		if not is_node_ready():
			return
		head_start_idx = get_skeleton().find_bone(v)



func _validate_property(property: Dictionary) -> void:
	
	var bone_names :=["right_thigh_name",
					"right_shin_name",
					"right_foot_name",
					"left_thigh_name",
					"left_shin_name",
					"left_foot_name",
					"right_shoulder_name",
					"right_up_arm_name",
					"right_fore_arm_name",
					"right_hand_name",
					"left_shoulder_name",
					"left_up_arm_name",
					"left_fore_arm_name",
					"left_hand_name",
					"spine_start_name",
					"hip_start_name",
					"chest_start_name",
					"neck_start_name",
					"head_start_name"
				]
	
	if property.name in bone_names:
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()



func snap_ball():
	ball.global_position = baked_animation.ball_pos
	ball.launch_vel_tangent_object.position = baked_animation.ball_launch_vel

@export var ball_positions : Array[Vector3]
func bake_ball_movement():
	ball_positions.clear()
	var delta := 1.0/30.0
	
	var _time := 0.0
	
	var vel := ball.launch_vel_tangent_object.position
	
	var gravity := 0.0
	
	var pos := ball.global_position
	
	while _time <= max_time:
		_time += delta
		if _time <= baked_animation.ball_launch_time:
			ball_positions.append(pos)
			continue
		pos += vel * delta
		vel.y += gravity * delta
		if pos.y  < 0.1:
			pos.y = 0.1
			vel.y = maxf(0.0, -vel.y) * 0.9
		
		vel *= 0.975
		
		ball_positions.append(pos)
		

func set_ball_pos():
	var idx := floori(time * 30.0)
	
	if ball_positions.size() == 0:
		bake_ball_movement()
	idx = clampi(idx, 0, ball_positions.size() - 1)
	
	ball_mesh.position = ball_positions[idx]
	


func interpolate_foot(is_right_foot : bool, time : float):
	var arr : Array[float]
	var nother_array : Array[BakedAnimator]
	var prev_foot_animator : BakedFootAnimator
	var next_foot_animator : BakedFootAnimator
	
	var thigh_idx : int
	var shin_idx : int
	var foot_idx : int
	
	if is_right_foot:
		arr = baked_animation.right_foot_track_holder.keyframe_times
		nother_array = baked_animation.right_foot_track_holder.baked_animators
		thigh_idx = right_thigh_idx
		shin_idx = right_shin_idx
		foot_idx = right_foot_idx
	else:
		arr = baked_animation.left_foot_track_holder.keyframe_times
		nother_array = baked_animation.left_foot_track_holder.baked_animators
		thigh_idx = left_thigh_idx
		shin_idx = left_shin_idx
		foot_idx = left_foot_idx
	var idxs := get_prev_and_next_keyframes(time, arr)
	var t := get_t_from_keyframes(time, arr, idxs[0], idxs[1])
	var dur := arr[idxs[1]] - arr[idxs[0]]
	prev_foot_animator = nother_array[idxs[0]]
	next_foot_animator = nother_array[idxs[1]]
	
	
	var interp_mode := prev_foot_animator.interp_mode
	
	var foot_offset := get_skeleton().get_bone_global_rest(foot_idx).basis.get_rotation_quaternion()
	
	match interp_mode:
		BakedFootAnimator.InterpMode.FK_HERMITE:
			
			var prev_thigh_quat : Quaternion
			var next_thigh_quat : Quaternion
			
			var prev_shin_quat : Quaternion
			var next_shin_quat : Quaternion
			
			var prev_foot_quat : Quaternion
			var next_foot_quat : Quaternion
			
			if prev_foot_animator.hits_ball:
				var pelvis_t := interpolate_pelvis_in_time(arr[idxs[0]])
				var hip_pos := get_hip_pos(pelvis_t, is_right_foot, arr[idxs[0]])
				
				var ball_pos := ball.position
				
				var ball_default_pos := baked_animation.ball_pos
				
				var delta := ball_pos - ball_default_pos
				
				var ik_target_pos := prev_foot_animator.ik_foot_transform.origin + delta
				
				var thigh_length := get_skeleton().get_bone_rest(shin_idx).origin.length()
				
				var shin_length :=  get_skeleton().get_bone_rest(foot_idx).origin.length()
				
				var quats := IkInterpstatic.get_ik_interpolation(hip_pos, ik_target_pos, thigh_length, shin_length, prev_foot_animator.ik_roll)
				prev_thigh_quat = pelvis_t.basis.get_rotation_quaternion().inverse() * quats[0]
				prev_shin_quat = quats[1]
				prev_foot_quat = quats[1].inverse() * quats[0].inverse() * prev_foot_animator.ik_foot_transform.basis.get_rotation_quaternion()
				if next_foot_animator.parent == BakedFootAnimator.Parent.PREV_ANIMATOR:
					var next_pelvis_t := interpolate_pelvis_in_time(arr[idxs[1]])
					var next_hip_pos := get_hip_pos(next_pelvis_t, is_right_foot, arr[idxs[0]])
					var next_ik_target_pos := next_foot_animator.ik_foot_transform.origin + delta
					var next_quats := IkInterpstatic.get_ik_interpolation(next_hip_pos, next_ik_target_pos, thigh_length, shin_length, next_foot_animator.ik_roll)
					next_thigh_quat = next_pelvis_t.basis.get_rotation_quaternion().inverse() * next_quats[0]
					next_shin_quat = next_quats[1]
					next_foot_quat = next_quats[1].inverse() * next_quats[0].inverse() * next_foot_animator.ik_foot_transform.basis.get_rotation_quaternion()
				else:
					next_thigh_quat = next_foot_animator.thigh_quat
					next_shin_quat = next_foot_animator.shin_quat
					next_foot_quat = next_foot_animator.foot_quat
					
			else:
				prev_thigh_quat = prev_foot_animator.thigh_quat
				prev_shin_quat = prev_foot_animator.shin_quat
				prev_foot_quat = prev_foot_animator.foot_quat

			if next_foot_animator.hits_ball:
				var pelvis_t := interpolate_pelvis_in_time(arr[idxs[1]])
				var hip_pos := get_hip_pos(pelvis_t, is_right_foot, arr[idxs[1]])
				
				var ball_pos := ball.position
				
				var ball_default_pos := baked_animation.ball_pos
				
				var delta := ball_pos - ball_default_pos
				
				var ik_target_pos := next_foot_animator.ik_foot_transform.origin + delta
				
				var thigh_length := get_skeleton().get_bone_rest(shin_idx).origin.length()
				
				var shin_length :=  get_skeleton().get_bone_rest(foot_idx).origin.length()
				
				var quats := IkInterpstatic.get_ik_interpolation(hip_pos, ik_target_pos, thigh_length, shin_length, next_foot_animator.ik_roll)
				next_thigh_quat = pelvis_t.basis.get_rotation_quaternion().inverse() * quats[0]
				next_shin_quat = quats[1]
				next_foot_quat = quats[1].inverse() * quats[0].inverse() * next_foot_animator.ik_foot_transform.basis.get_rotation_quaternion()
			else:
				next_thigh_quat = next_foot_animator.thigh_quat
				next_shin_quat = next_foot_animator.shin_quat
				next_foot_quat = next_foot_animator.foot_quat

			var prev_thigh_rot := prev_thigh_quat
			var prev_thigh_tangent := prev_foot_animator.thigh_tangent_vector
			var prev_thigh_mag := prev_foot_animator.thigh_tangent_magnitude
			
			var next_thigh_rot := next_thigh_quat
			var next_thigh_tangent := next_foot_animator.thigh_tangent_vector
			var next_thigh_mag := next_foot_animator.thigh_tangent_magnitude
			
			var thigh_ease_curve := next_foot_animator.thigh_ease_curve
			
			get_skeleton().set_bone_pose_rotation(thigh_idx, QuaternionExtender.my_quat_interpolate(prev_thigh_rot, prev_thigh_tangent, prev_thigh_mag, next_thigh_rot, next_thigh_tangent, next_thigh_mag, t, dur, thigh_ease_curve.baked_points))
			
			var prev_shin_rot := prev_shin_quat
			var prev_shin_tangent := prev_foot_animator.shin_tangent_vector
			var prev_shin_mag := prev_foot_animator.shin_tangent_magnitude
			
			var next_shin_rot := next_shin_quat
			var next_shin_tangent := next_foot_animator.shin_tangent_vector
			var next_shin_mag := next_foot_animator.shin_tangent_magnitude
			
			var shin_ease_curve := next_foot_animator.shin_ease_curve
			
			get_skeleton().set_bone_pose_rotation(shin_idx, QuaternionExtender.my_quat_interpolate(prev_shin_rot, prev_shin_tangent, prev_shin_mag, next_shin_rot, next_shin_tangent, next_shin_mag, t, dur, shin_ease_curve.baked_points))
			
			var prev_foot_rot := prev_foot_quat
			var prev_foot_tangent := prev_foot_animator.foot_tangent_vector
			var prev_foot_mag := prev_foot_animator.foot_tangent_magnitude
			
			var next_foot_rot := next_foot_quat
			var next_foot_tangent := next_foot_animator.foot_tangent_vector
			var next_foot_mag := next_foot_animator.foot_tangent_magnitude
			
			var foot_ease_curve := next_foot_animator.foot_ease_curve
			
			get_skeleton().set_bone_pose_rotation(foot_idx,
			QuaternionExtender.my_quat_interpolate(prev_foot_rot, prev_foot_tangent, prev_foot_mag, next_foot_rot, next_foot_tangent, next_foot_mag, t, dur, foot_ease_curve.baked_points) * foot_offset)
			
		BakedFootAnimator.InterpMode.IK:
			var thigh_pos := get_skeleton().get_bone_global_pose(thigh_idx).origin
			
			var roll := lerp_angle(prev_foot_animator.ik_roll, next_foot_animator.ik_roll, t)
			
			var trsf := prev_foot_animator.ik_foot_transform.interpolate_with(next_foot_animator.ik_foot_transform, t)
			
			var quats := IkInterpstatic.get_ik_interpolation(thigh_pos, trsf.origin, get_skeleton().get_bone_rest(shin_idx).origin.length(), get_skeleton().get_bone_rest(foot_idx).origin.length(), roll)
			
			get_skeleton().set_bone_pose_rotation(thigh_idx, get_skeleton().get_bone_global_pose(spine_start_idx).basis.get_rotation_quaternion().inverse() * quats[0])
			get_skeleton().set_bone_pose_rotation(shin_idx, quats[1])
			get_skeleton().set_bone_pose_rotation(foot_idx ,quats[1].inverse() * quats[0].inverse() * trsf.basis.get_rotation_quaternion() * foot_offset)

func interpolate_hands(is_right_hand : bool, time : float):
	var arr : Array[float]
	var nother : Array[BakedAnimator]
	var prev_hand_animator : BakedHandAnimator
	var next_hand_animator : BakedHandAnimator
	
	var shoulder_idx : int
	var up_arm_idx : int
	var fore_arm_idx : int
	var hand_idx : int
	
	if is_right_hand:
		arr = baked_animation.right_hand_track_holder.keyframe_times
		nother = baked_animation.right_hand_track_holder.baked_animators
		shoulder_idx = right_shoulder_idx
		up_arm_idx = right_up_arm_idx
		fore_arm_idx = right_fore_arm_idx
		hand_idx = right_hand_idx
	else:
		arr = baked_animation.left_hand_track_holder.keyframe_times
		nother = baked_animation.left_hand_track_holder.baked_animators
		shoulder_idx = left_shoulder_idx
		up_arm_idx = left_up_arm_idx
		fore_arm_idx = left_fore_arm_idx
		hand_idx = left_hand_idx
	var idxs := get_prev_and_next_keyframes(time, arr)
	var t := get_t_from_keyframes(time, arr, idxs[0], idxs[1])
	var dur := arr[idxs[1]] - arr[idxs[0]]
	prev_hand_animator = nother[idxs[0]]
	next_hand_animator = nother[idxs[1]]
	
	var prev_shoulder_rot := prev_hand_animator.shoulder_quat
	var prev_shoulder_tangent := prev_hand_animator.shoulder_tangent_vector
	var prev_shoulder_mag := prev_hand_animator.shoulder_tangent_magnitude
	
	var next_shoulder_rot := next_hand_animator.shoulder_quat
	var next_shoulder_tangent := next_hand_animator.shoulder_tangent_vector
	var next_shoulder_mag := next_hand_animator.shoulder_tangent_magnitude
	
	var shoulder_ease_curve := next_hand_animator.shoulder_ease_curve
	
	get_skeleton().set_bone_pose_rotation(shoulder_idx, QuaternionExtender.my_quat_interpolate(prev_shoulder_rot, prev_shoulder_tangent, prev_shoulder_mag, next_shoulder_rot, next_shoulder_tangent, next_shoulder_mag, t, dur, shoulder_ease_curve.baked_points))
	
	var prev_up_arm_rot := prev_hand_animator.up_arm_quat
	var prev_up_arm_tangent := prev_hand_animator.up_arm_tangent_vector
	var prev_up_arm_mag := prev_hand_animator.up_arm_tangent_magnitude
	
	var next_up_arm_rot := next_hand_animator.up_arm_quat
	var next_up_arm_tangent := next_hand_animator.up_arm_tangent_vector
	var next_up_arm_mag := next_hand_animator.up_arm_tangent_magnitude
	
	var up_arm_ease_curve := next_hand_animator.up_arm_ease_curve
	
	get_skeleton().set_bone_pose_rotation(up_arm_idx, QuaternionExtender.my_quat_interpolate(prev_up_arm_rot, prev_up_arm_tangent, prev_up_arm_mag, next_up_arm_rot, next_up_arm_tangent, next_up_arm_mag, t, dur, up_arm_ease_curve.baked_points))
	
	var prev_fore_arm_rot := prev_hand_animator.fore_arm_quat
	var prev_fore_arm_tangent := prev_hand_animator.fore_arm_tangent_vector
	var prev_fore_arm_mag := prev_hand_animator.fore_arm_tangent_magnitude
	
	var next_fore_arm_rot := next_hand_animator.fore_arm_quat
	var next_fore_arm_tangent := next_hand_animator.fore_arm_tangent_vector
	var next_fore_arm_mag := next_hand_animator.fore_arm_tangent_magnitude
	
	var fore_arm_ease_curve := next_hand_animator.fore_arm_ease_curve
	
	get_skeleton().set_bone_pose_rotation(fore_arm_idx, QuaternionExtender.my_quat_interpolate(prev_fore_arm_rot, prev_fore_arm_tangent, prev_fore_arm_mag, next_fore_arm_rot, next_fore_arm_tangent, next_fore_arm_mag, t, dur, fore_arm_ease_curve.baked_points))
	
	var prev_hand_rot := prev_hand_animator.hand_quat
	var prev_hand_tangent := prev_hand_animator.hand_tangent_vector
	var prev_hand_mag := prev_hand_animator.hand_tangent_magnitude
	
	var next_hand_rot := next_hand_animator.hand_quat
	var next_hand_tangent := next_hand_animator.hand_tangent_vector
	var next_hand_mag := next_hand_animator.hand_tangent_magnitude
	
	var hand_ease_curve := next_hand_animator.hand_ease_curve
	
	get_skeleton().set_bone_pose_rotation(hand_idx, QuaternionExtender.my_quat_interpolate(prev_hand_rot, prev_hand_tangent, prev_hand_mag, next_hand_rot, next_hand_tangent, next_hand_mag, t, dur, hand_ease_curve.baked_points))

func get_prev_and_next_keyframes(time : float, arr : Array[float]) -> Array[int]:
	
	var last_idx := 0
	
	for i in range(arr.size() - 1):
		last_idx = i
		if arr[i+1] > time:
			break
		
	var next_idx := last_idx + 1
	
	if next_idx >= arr.size():
		next_idx = arr.size() - 1
		last_idx = next_idx - 1
	
	return [last_idx, next_idx]

func get_t_from_keyframes(time : float, arr : Array[float], prev_idx : int, next_idx : int) -> float:
	return clampf(remap(time, arr[prev_idx], arr[next_idx], 0, 1), 0, 1)

func _process_modification_with_delta(delta: float) -> void:
	
	var new_ball_pos := ball.position
	var new_ball_tangent := ball.launch_vel_tangent_object.position
	
	if new_ball_pos != prev_ball_pos or new_ball_tangent != prev_ball_tangent:
		bake_ball_movement()
		prev_ball_pos = new_ball_pos
		prev_ball_tangent = new_ball_tangent
	
	set_ball_pos()
	
	if playing:
		time += delta
		if time > max_time:
			time = 0
	else:
		time = clampf(time, 0, max_time)
	
	interpolate_root_in_time(time)
	#
	interpolate_spine(time)
	
	interpolate_head(time)
	
	interpolate_foot(true, time)
	interpolate_foot(false, time)
	
	interpolate_hands(true, time)
	interpolate_hands(false, time)

func interpolate_root_in_time(time) -> void:
	get_skeleton().set_bone_pose(0, get_root_transform(time))

func get_root_transform(time : float) -> Transform3D:
	var arr := baked_animation.root_track_holder.keyframe_times
	
	var idxs := get_prev_and_next_keyframes(time, arr)
	
	var animators := baked_animation.root_track_holder.baked_animators
	
	var animator_1 : BakedRootAnimator = animators[idxs[0]]
	var animator_2 : BakedRootAnimator = animators[idxs[1]]
	
	var t := get_t_from_keyframes(time, arr, idxs[0], idxs[1])
	var dur := arr[idxs[1]] - arr[idxs[0]]
	
	var rot := QuaternionExtender.my_quat_interpolate(animator_1.root_transform.basis.get_rotation_quaternion(), animator_1.root_rot_vector, animator_1.root_rot_magnitude,
	animator_2.root_transform.basis.get_rotation_quaternion(), animator_2.root_rot_vector, animator_2.root_rot_magnitude, t, dur, animator_2.root_rot_ease_curve.baked_points)
	#
	var loc := MyCurve3D.interpolate(animator_1.root_transform.origin, animator_1.root_loc_vector * animator_1.root_loc_magnitude, animator_2.root_transform.origin, animator_2.root_loc_vector * animator_2.root_loc_magnitude, t, dur, animator_2.root_loc_ease_curve.baked_points)
	#
	return Transform3D(rot, loc) * get_skeleton().get_bone_global_rest(0)

func interpolate_pelvis_basis(animator_1 : BakedSpineAnimator, animator_2 : BakedSpineAnimator, t : float, dur : float) -> Quaternion:
	var b_1 := animator_1.pelvis_transform.basis.get_rotation_quaternion()
	var b_2 := animator_2.pelvis_transform.basis.get_rotation_quaternion()
	
	var pelvis_r_velocity_vector_1 := animator_1.pelvis_rot_tangent_vector
	var pelvis_r_velocity_mag_1 := animator_1.pelvis_rot_tangent_magnitude
	
	var pelvis_r_velocity_vector_2 := animator_2.pelvis_rot_tangent_vector
	
	var pelvis_r_velocity_mag_2 := animator_2.pelvis_rot_tangent_magnitude
	
	var super_t := QuaternionExtender.my_quat_interpolate(b_1, pelvis_r_velocity_vector_1, pelvis_r_velocity_mag_1, b_2, pelvis_r_velocity_vector_2, pelvis_r_velocity_mag_2, t,dur, animator_2.pelvis_rot_curve.baked_points)

	return super_t

func interpolate_pelvis_loc(animator_1 : BakedSpineAnimator, animator_2 : BakedSpineAnimator, t : float, dur : float) -> Vector3:
	
	var loc_1 := animator_1.pelvis_transform.origin
	var loc_2 := animator_2.pelvis_transform.origin
	
	var root_1_b := Basis()
	var root_2_b := Basis()
	
	var g_vector_1 := animator_1.pelvis_loc_tangent_vector
	var g_vector_2 := animator_2.pelvis_loc_tangent_vector
	
	var g_mag_1 := animator_1.pelvis_loc_tangent_magnitude
	var g_mag_2 := animator_2.pelvis_loc_tangent_magnitude
	
	var velocity_vector_1 := root_1_b.inverse() * (g_vector_1 * g_mag_1)
	var velocity_vector_2 := root_2_b.inverse() * (g_vector_2 * g_mag_2)
	
	var loc := MyCurve3D.interpolate(loc_1, velocity_vector_1, loc_2, velocity_vector_2, t, dur, animator_2.pelvis_loc_curve.baked_points)
	
	return loc

func interpolate_hip_basis(animator_1 : BakedSpineAnimator, animator_2 : BakedSpineAnimator, t : float, dur : float) -> Quaternion:
	var b_1 := animator_1.hip_quat
	var b_2 := animator_2.hip_quat
	var hip_r_velocity_vector_1 := animator_1.hip_rot_tangent_vector
	var hip_r_velocity_vector_2 := animator_2.hip_rot_tangent_vector
	
	var hip_r_vel_mag_1 := animator_1.hip_rot_tangent_magnitude
	var hip_r_vel_mag_2 := animator_2.hip_rot_tangent_magnitude
	
	
	var super_t := QuaternionExtender.my_quat_interpolate(b_1, hip_r_velocity_vector_1, hip_r_vel_mag_1, b_2, hip_r_velocity_vector_2, hip_r_vel_mag_2, t, dur, animator_2.hip_rot_curve.baked_points)

	return super_t

func interpolate_chest_basis(animator_1 : BakedSpineAnimator, animator_2 : BakedSpineAnimator, t : float, dur : float) -> Quaternion:
	var b_1 := animator_1.chest_quat
	var b_2 := animator_2.chest_quat
	var chest_r_velocity_vector_1 := animator_1.chest_rot_tangent_vector
	var chest_r_velocity_vector_2 := animator_2.chest_rot_tangent_vector
	
	var chest_r_vel_mag_1 := animator_1.chest_rot_tangent_magnitude
	var chest_r_vel_mag_2 := animator_2.chest_rot_tangent_magnitude
	
	
	var super_t := QuaternionExtender.my_quat_interpolate(b_1, chest_r_velocity_vector_1, chest_r_vel_mag_1, b_2, chest_r_velocity_vector_2, chest_r_vel_mag_2, t, dur, animator_2.chest_rot_curve.baked_points)

	return super_t

func interpolate_spine(time : float):
	var root_tr := get_root_transform(time)
	
	var transforms := get_spine_transforms(time, root_tr)
	
	get_skeleton().set_bone_pose_position(spine_start_idx, root_tr.inverse() * transforms[0].origin)
	#
	var prev := transforms[0].basis.get_rotation_quaternion()
	get_skeleton().set_bone_pose_rotation(spine_start_idx, root_tr.basis.inverse().get_rotation_quaternion() * (prev as Quaternion))
	for i in range(1, transforms.size(), 1):
		get_skeleton().set_bone_pose_rotation(spine_start_idx + i, prev.inverse() * (transforms[i].basis.get_rotation_quaternion()))
		prev = transforms[i].basis.get_rotation_quaternion()

func get_hip_pos(pelvis_t : Transform3D, right : bool, time : float) -> Vector3:
	var hip_local := get_skeleton().get_bone_rest(right_thigh_idx if right else left_thigh_idx).origin
	return pelvis_t * hip_local

func interpolate_pelvis_in_time(time : float) -> Transform3D:
	var root_tr := get_root_transform(time)
	return get_spine_transforms(time, root_tr)[0]

func get_spine_transforms(time : float, root_transform : Transform3D) -> Array[Transform3D]:
	
	var arr := baked_animation.spine_track_holder.keyframe_times
	
	var idxs := get_prev_and_next_keyframes(time, arr)
	
	var animators := baked_animation.spine_track_holder.baked_animators
	
	var animator_1 : BakedSpineAnimator = animators[idxs[0]]
	var animator_2 : BakedSpineAnimator = animators[idxs[1]]
	
	var t := get_t_from_keyframes(time, arr, idxs[0], idxs[1])
	var dur := arr[idxs[1]] - arr[idxs[0]]
	
	var super_t := interpolate_pelvis_basis(animator_1, animator_2, t, dur)
	var hip_b := interpolate_hip_basis(animator_1, animator_2, t, dur)
	var chest_b := interpolate_chest_basis(animator_1, animator_2, t, dur)
	
	var super_t_location := interpolate_pelvis_loc(animator_1, animator_2, t, dur)
	var super_t_transform := Transform3D(super_t, super_t_location)
		
	var transforms := get_transforms_from_drivers(root_transform, super_t_transform, hip_b, chest_b)
	
	return transforms

func interpolate_head(time : float):
	var arr := baked_animation.head_track_holder.keyframe_times
	var nother_arr := baked_animation.head_track_holder.baked_animators
	
	var idxs := get_prev_and_next_keyframes(time, arr)
	
	var animator_1 : BakedHeadAnimator = nother_arr[idxs[0]]
	var animator_2 : BakedHeadAnimator = nother_arr[idxs[1]]
	
	var t := get_t_from_keyframes(time, arr, idxs[0], idxs[1])
	var dur := arr[idxs[1]] - arr[idxs[0]]
	
	var neck_offset_1 := animator_1.neck_offset_quat
	var neck_tangent_1 := animator_1.neck_rot_tangent_vector
	var neck_mag_1 := animator_1.neck_rot_tangent_magnitude
	
	var neck_offset_2 := animator_2.neck_offset_quat
	var neck_tangent_2 := animator_2.neck_rot_tangent_vector
	var neck_mag_2 := animator_2.neck_rot_tangent_magnitude
	
	var neck_curve := animator_2.neck_ease_curve
	
	var neck_offset := QuaternionExtender.my_quat_interpolate(neck_offset_1, neck_tangent_1, neck_mag_1, neck_offset_2, neck_tangent_2, neck_mag_2, t, dur, neck_curve.baked_points)
	
	var offset_scaled  := neck_offset.slerp(Quaternion.IDENTITY, 0.5)
	
	var neck_start := neck_start_idx
	var neck_end := neck_start + 1
	
	get_skeleton().set_bone_pose_rotation(neck_start, offset_scaled * get_skeleton().get_bone_rest(neck_start).basis.get_rotation_quaternion())
	get_skeleton().set_bone_pose_rotation(neck_end, offset_scaled * get_skeleton().get_bone_rest(neck_end).basis.get_rotation_quaternion())
	
	var head_1 := animator_1.head_quat
	var head_tangent_1 := animator_1.head_rot_tangent_vector
	var head_mag_1 := animator_1.head_rot_tangent_magnitude
	
	var head_2 := animator_2.head_quat
	var head_tangent_2 := animator_1.head_rot_tangent_vector
	var head_mag_2 := animator_1.head_rot_tangent_magnitude
	
	var head_curve := animator_2.head_ease_curve
	
	var head_quat := QuaternionExtender.my_quat_interpolate(head_1, head_tangent_1, head_mag_1, head_2, head_tangent_2, head_mag_2, t, dur, head_curve.baked_points)
	
	get_skeleton().set_bone_pose_rotation(head_start_idx, head_quat)
	
# Used chatgpt to convert correctly
func get_transforms_from_drivers(
		root_global: Transform3D,
		pelvis_as_parent: Transform3D,
		hip_local: Basis,
		chest_local: Basis
	) -> Array[Transform3D]:

	var transforms: Array[Transform3D]
	var rest_transforms: Array[Transform3D]

	for i in range(spine_start_idx, chest_start_idx + 1):
		rest_transforms.append(get_skeleton().get_bone_global_rest(i))

	transforms = rest_transforms.duplicate()

	# Convert bone indices to indices relative to the local transforms array.
	var hip_local_idx := hip_start_idx - spine_start_idx
	var chest_local_idx := chest_start_idx - spine_start_idx

	var pelvis_global := root_global * pelvis_as_parent
	var hip_global := pelvis_global.basis * hip_local
	var chest_global := pelvis_global.basis * chest_local

	var pelvis_rest := rest_transforms[0]
	var pelvis_offset := pelvis_global

	var global_pos_offset := pelvis_global.origin - pelvis_rest.origin

	# -------------------------------------------------------------------------
	# Start by applying the pelvis transform to the entire chain.
	# -------------------------------------------------------------------------

	transforms[0].basis = (pelvis_offset * rest_transforms[0]).basis
	transforms[0].origin += global_pos_offset

	var old := transforms[0]

	for i in range(1, transforms.size()):
		transforms[i].basis = (pelvis_offset * rest_transforms[i]).basis

		transforms[i].origin = old.origin \
			+ (old.basis * rest_transforms[i - 1].basis.inverse()) \
			* (rest_transforms[i].origin - rest_transforms[i - 1].origin)

		old = transforms[i]

	# -------------------------------------------------------------------------
	# Interpolate from pelvis -> hip for the bones before the hip.
	# -------------------------------------------------------------------------

	old = transforms[hip_local_idx]

	for i in range(hip_local_idx - 1, -1, -1):
		var start := pelvis_global.basis.orthonormalized()
		var end := hip_global.orthonormalized()

		var t := float(i) / float(hip_local_idx)
		t = 1.0 - t

		var offset := start.slerp(end, t)

		transforms[i].basis = offset * rest_transforms[i].basis

		transforms[i].origin = old.origin \
			+ offset * (rest_transforms[i].origin - rest_transforms[i + 1].origin)

		old = transforms[i]

	# -------------------------------------------------------------------------
	# Interpolate from pelvis -> chest for the hip and bones after it.
	# -------------------------------------------------------------------------

	old = transforms[hip_local_idx]

	var old_offset := pelvis_offset.basis

	for i in range(hip_local_idx, transforms.size()):
		var start := pelvis_global.basis.orthonormalized()
		var end := chest_global.orthonormalized()

		var t := float(i + 1 - hip_local_idx) \
			/ float(transforms.size() - hip_local_idx)

		var offset := start.slerp(end, t)

		transforms[i].basis = offset * rest_transforms[i].basis

		if i != hip_local_idx:
			transforms[i].origin = old.origin \
				+ old_offset * (rest_transforms[i].origin - rest_transforms[i - 1].origin)

		old_offset = offset
		old = transforms[i]

	return transforms
