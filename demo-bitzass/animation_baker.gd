extends Node3D

@export var anim_name : String

@export var scene_to_bake : PackedScene

@export var world_environment: WorldEnvironment

@export var ball_kf_idx := 0

var animation_editor : AnimationEditor:
	get:
		if not animation_editor:
			animation_editor = scene_to_bake.instantiate()
		return animation_editor

var baked_animation : BakedAnimation

var folder_path := "res://export/baked_animations/"

func bake():
	baked_animation = BakedAnimation.new()
	
	var ball_key_frames := animation_editor.ball_key_frames
	
	var b_kf := ball_key_frames.ball_ks[ball_kf_idx]
	
	var ball_pos := b_kf.pos.position
	var launch_time := b_kf.time
	var ball_launch_vel : Vector3
	
	if ball_kf_idx >= ball_key_frames.ball_ks.size() - 1:
		ball_launch_vel = Vector3.ZERO
	else:
		var next_time := ball_key_frames.ball_ks[ball_kf_idx + 1].time
		var dur := next_time - launch_time
		if dur > 0:
			ball_launch_vel = b_kf.out_tangent.position / dur * 3.0
		else:
			ball_launch_vel = Vector3.ZERO
	
	baked_animation.ball_pos = ball_pos
	baked_animation.ball_launch_time = launch_time
	baked_animation.ball_launch_vel = ball_launch_vel
	
	baked_animation.right_foot_track_holder = BakedTrackHolder.new()
	baked_animation.left_foot_track_holder = BakedTrackHolder.new()
	
	baked_animation.right_hand_track_holder = BakedTrackHolder.new()
	baked_animation.left_hand_track_holder = BakedTrackHolder.new()
	
	baked_animation.spine_track_holder = BakedTrackHolder.new()
	
	baked_animation.head_track_holder = BakedTrackHolder.new()
	
	baked_animation.root_track_holder = BakedTrackHolder.new()
	
	var right_foot_anim_track_holder := animation_editor.right_foot_holder
	var left_foot_anim_track_holder := animation_editor.left_foot_holder
	
	var foot_holders : Array[AnimTrackHolder] = [right_foot_anim_track_holder, left_foot_anim_track_holder]
	
	var right := true
	
	for h in foot_holders:
		for k in h.keyframes:
			var new_animator := BakedFootAnimator.new()
			
			var non_baked_animator := k.animator as FootAnimator
			
			new_animator.hip_pos = non_baked_animator.foot_ik_pose_roll.position
			
			new_animator.thigh_ease_curve = non_baked_animator.thigh_rot_curve.duplicate(true)
			new_animator.shin_ease_curve = non_baked_animator.shin_rot_curve.duplicate(true)
			new_animator.foot_ease_curve = non_baked_animator.foot_rot_curve.duplicate(true)
			
			match non_baked_animator.interp_mode:
				FootAnimator.InterpMode.FK_HERMITE:
					new_animator.interp_mode = BakedFootAnimator.InterpMode.FK_HERMITE
				FootAnimator.InterpMode.IK_HERMITE:
					new_animator.interp_mode = BakedFootAnimator.InterpMode.IK
				FootAnimator.InterpMode.CONSTANT:
					new_animator.interp_mode = BakedFootAnimator.InterpMode.CONSTANT
			new_animator.thigh_quat = non_baked_animator.thigh_pose.basis.get_rotation_quaternion()
			new_animator.shin_quat = non_baked_animator.shin_pose.basis.get_rotation_quaternion()
			new_animator.foot_quat = non_baked_animator.foot_pose.basis.get_rotation_quaternion()
			
			new_animator.is_on_ground = non_baked_animator.is_on_ground
			
			new_animator.ik_foot_transform = non_baked_animator.foot_ik_pose.transform
			
			new_animator.ik_roll = non_baked_animator.foot_ik_pose_roll.rotation.y
			
			new_animator.thigh_tangent_vector = non_baked_animator.thigh_tangent.basis.get_rotation_quaternion().get_axis()
			new_animator.shin_tangent_vector = non_baked_animator.shin_tangent.basis.get_rotation_quaternion().get_axis()
			new_animator.foot_tangent_vector = non_baked_animator.foot_tangent.basis.get_rotation_quaternion().get_axis()
				
			new_animator.thigh_tangent_magnitude = non_baked_animator.thigh_angular_velocity
			new_animator.shin_tangent_magnitude = non_baked_animator.shin_angular_velocity
			new_animator.foot_tangent_magnitude = non_baked_animator.foot_angular_velocity
			
			(baked_animation.right_foot_track_holder if right else baked_animation.left_foot_track_holder).baked_animators.append(new_animator)
			(baked_animation.right_foot_track_holder if right else baked_animation.left_foot_track_holder).keyframe_times.append(k.time)
			
		right = false
	
	var right_hand_anim_track_holder := animation_editor.right_hand_holder
	var left_hand_anim_track_holder := animation_editor.left_hand_holder
	
	var hand_holders : Array[AnimTrackHolder] = [right_hand_anim_track_holder, left_hand_anim_track_holder]
	right = true
	for h in hand_holders:
		for k in h.keyframes:
			var new_animator := BakedHandAnimator.new()
			
			var non_baked_animator := k.animator as HandsAnimator
			
			new_animator.shoulder_ease_curve = non_baked_animator.shoulder_ease_curve.duplicate(true)
			new_animator.up_arm_ease_curve = non_baked_animator.up_arm_ease_curve.duplicate(true)
			new_animator.fore_arm_ease_curve = non_baked_animator.low_arm_ease_curve.duplicate(true)
			new_animator.hand_ease_curve = non_baked_animator.hand_ease_curve.duplicate(true)
			
			new_animator.shoulder_quat = non_baked_animator.shoulder_pose.basis.get_rotation_quaternion()
			new_animator.up_arm_quat = non_baked_animator.up_arm_pose.basis.get_rotation_quaternion()
			new_animator.fore_arm_quat = non_baked_animator.low_arm_pose.basis.get_rotation_quaternion()
			new_animator.hand_quat = non_baked_animator.hand_pose.basis.get_rotation_quaternion()
			
			new_animator.ik_hand_transform = non_baked_animator.ik_target.transform
			
			new_animator.ik_roll = non_baked_animator.ik_roll.rotation.y
			
			new_animator.shoulder_tangent_vector = non_baked_animator.shoulder_tangent
			new_animator.up_arm_tangent_vector = non_baked_animator.up_arm_tangent
			new_animator.fore_arm_tangent_vector = non_baked_animator.low_arm_tangent
			new_animator.hand_tangent_vector = non_baked_animator.hand_tangent
			
			
			new_animator.shoulder_tangent_magnitude = non_baked_animator.shoulder_angular_velocity
			new_animator.up_arm_tangent_magnitude = non_baked_animator.up_arm_angular_velocity
			new_animator.fore_arm_tangent_magnitude = non_baked_animator.low_arm_angular_velocity
			new_animator.hand_tangent_magnitude = non_baked_animator.hand_angular_velocity
			
			(baked_animation.right_hand_track_holder if right else baked_animation.left_hand_track_holder).baked_animators.append(new_animator)
			(baked_animation.right_hand_track_holder if right else baked_animation.left_hand_track_holder).keyframe_times.append(k.time)
			
		right = false
	
	var spine_holder := animation_editor.spine_holder
	
	for k in spine_holder.keyframes:
		var spine_animator := BakedSpineAnimator.new()
		
		var non_baked_animator := k.animator as SpineAnimator
		
		spine_animator.root_transform = non_baked_animator.root.transform
		
		spine_animator.pelvis_transform = non_baked_animator.pelvis_root.transform
		
		spine_animator.pelvis_loc_tangent_vector = non_baked_animator.pelvis_g_tangent_vector
		spine_animator.pelvis_loc_tangent_magnitude = non_baked_animator.pelvis_g_vel
		spine_animator.pelvis_loc_curve = non_baked_animator.pelvis_loc_ease_curve
		
		
		spine_animator.pelvis_rot_tangent_vector = non_baked_animator.pelvis_r_tangent_vector
		spine_animator.pelvis_rot_tangent_magnitude = non_baked_animator.pelvis_r_vel
		spine_animator.pelvis_rot_curve = non_baked_animator.pelvis_rot_ease_curve.duplicate(true)
		
		spine_animator.hip_quat = non_baked_animator.hip_pose.basis.get_rotation_quaternion()
		
		spine_animator.hip_rot_tangent_vector = non_baked_animator.hips_r_tangent_vector
		spine_animator.hip_rot_tangent_magnitude = non_baked_animator.hip_r_vel
		spine_animator.hip_rot_curve = non_baked_animator.hip_rot_ease_curve.duplicate(true)
		
		spine_animator.chest_quat = non_baked_animator.chest_pose.basis.get_rotation_quaternion()
		
		spine_animator.chest_rot_tangent_vector = non_baked_animator.chest_r_tangent_vector
		spine_animator.chest_rot_tangent_magnitude = non_baked_animator.chest_r_vel
		spine_animator.chest_rot_curve = non_baked_animator.chest_rot_ease_curve.duplicate(true)
		
		baked_animation.spine_track_holder.baked_animators.append(spine_animator)
		baked_animation.spine_track_holder.keyframe_times.append(k.time)
	
	var head_holder := animation_editor.head_holder
	
	for k in head_holder.keyframes:
		var head_animator := BakedHeadAnimator.new()
		var non_baked_animator := k.animator as HeadAnimator
		
		head_animator.neck_offset_quat = non_baked_animator.neck_control.basis.get_rotation_quaternion()
		head_animator.neck_rot_tangent_vector = non_baked_animator.neck_tangent_vector
		head_animator.neck_rot_tangent_magnitude = non_baked_animator.neck_vel_magnitude
		head_animator.neck_ease_curve = non_baked_animator.neck_ease_curve

		head_animator.head_quat = non_baked_animator.head.basis.get_rotation_quaternion()
		head_animator.head_rot_tangent_vector = non_baked_animator.head_tangent_vector
		head_animator.head_rot_tangent_magnitude = non_baked_animator.head_vel_magnitude
		head_animator.head_ease_curve = non_baked_animator.head_ease_curve
		
		baked_animation.head_track_holder.baked_animators.append(head_animator)
		baked_animation.head_track_holder.keyframe_times.append(k.time)

	var root_holder := animation_editor.root_holder
	
	for k in root_holder.keyframes:
		var root_animator := BakedRootAnimator.new()
		var non_baked_animator := k.animator as RootAnimator
		
		root_animator.root_transform = non_baked_animator.root.transform
		
		root_animator.root_loc_vector = non_baked_animator.velocity_tangent_vector.normalized()
		root_animator.root_loc_magnitude = non_baked_animator.velocity_tangent_vector.length()
		root_animator.root_loc_ease_curve = non_baked_animator.loc_ease_curve
		
		root_animator.root_rot_vector = non_baked_animator.angular_velocity_tangent.normalized()
		root_animator.root_rot_magnitude = non_baked_animator.angular_velocity_amount
		root_animator.root_rot_ease_curve = non_baked_animator.rot_ease_curve
		
		baked_animation.root_track_holder.baked_animators.append(root_animator)
		baked_animation.root_track_holder.keyframe_times.append(k.time)
	
	
	
	ResourceSaver.save(baked_animation, folder_path + anim_name + ".res")
	(world_environment.environment.sky.sky_material as ProceduralSkyMaterial).sky_top_color = Color(randf(), randf(), randf())
	(world_environment.environment.sky.sky_material as ProceduralSkyMaterial).sky_horizon_color = Color(randf(), randf(), randf())
	(world_environment.environment.sky.sky_material as ProceduralSkyMaterial).ground_bottom_color = Color(randf(), randf(), randf())
	(world_environment.environment.sky.sky_material as ProceduralSkyMaterial).ground_horizon_color = Color(randf(), randf(), randf())

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			bake()
