@tool
extends BodyPartInterpolator
class_name FootInterpolator

@export var is_right_foot := true:
	set(v):
		is_right_foot = v
		if not is_node_ready():
			return
		anim_track_holder.is_right = is_right_foot

@export var thigh_rot_setter : BoneRotSetter
@export var shin_rot_setter : BoneRotSetter
@export var foot_rot_setter : BoneRotSetter

@export var thigh_name : String:
	set(v):
		thigh_name = v
		if not is_node_ready():
			return
		thigh_id = get_skeleton().find_bone(thigh_name)
@export var shin_name : String:
	set(v):
		shin_name = v
		if not is_node_ready():
			return
		shin_id = get_skeleton().find_bone(shin_name)
		
@export var foot_name : String:
	set(v):
		foot_name = v
		if not is_node_ready():
			return
		foot_id = get_skeleton().find_bone(foot_name)

@export var thigh_id : int
@export var shin_id : int
@export var foot_id : int

@export var spine_bone_modifier : SpineBoneModifier

const PELVIS_IDX := 1

var pelvis_rest : Transform3D

var thigh_offset_to_pelvis : Vector3

func _ready() -> void:
	super()
	is_right_foot = is_right_foot
	thigh_name = thigh_name
	shin_name = shin_name
	foot_name = foot_name
	pelvis_rest = get_skeleton().get_bone_global_rest(PELVIS_IDX)
	
	thigh_offset_to_pelvis = get_skeleton().get_bone_global_rest(thigh_id).origin - pelvis_rest.origin
	

func _validate_property(property: Dictionary) -> void:
	if property.name == "thigh_name" or property.name == "shin_name" or property.name == "foot_name":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()

func _process_modification_with_delta(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	on_time_changed(anim_track_holder.time)
	interpolate_keyframes()

func on_keyframe_added(key : Keyframe):
	var pasted : bool = key.get_meta("was_pasted", false)
	if pasted:
		return
	if anim_track_holder.keyframes.size() > 1:
		# 1 bc of order of things happening
		await modification_processed
	else:
		await spine_bone_modifier.modification_processed
	var animator := key.animator as FootAnimator
	animator.foot_rot_curve = MyEaseInOut.new()
	animator.shin_rot_curve = MyEaseInOut.new()
	animator.foot_rot_curve = MyEaseInOut.new()
	var pelvis_id := get_skeleton().get_bone_parent(thigh_id)
	
	var pd := get_skeleton().get_bone_global_pose(pelvis_id)
	
	animator.pelvis.global_transform = pd
	
	var tt := get_skeleton().get_bone_pose(thigh_id)
	var st := get_skeleton().get_bone_pose(shin_id)
	var foot_offset := get_skeleton().get_bone_global_rest(foot_id).basis.inverse()
	var ft := get_skeleton().get_bone_pose(foot_id)
	ft.basis = foot_offset * ft.basis
	animator.thigh_length = st.origin.length()
	animator.shin_length = ft.origin.length()
	var thigh_pose := animator.thigh_pose
	thigh_pose.transform = tt
	animator.thigh_tangent.position = Vector3.ZERO
	var shin_pose := animator.shin_pose
	shin_pose.transform = st
	var foot_pose := animator.foot_pose
	foot_pose.transform = ft
	var foot_ik_pose := animator.foot_ik_pose
	foot_ik_pose.global_transform = foot_pose.global_transform
	var ik_roll := animator.foot_ik_pose_roll
	
	ik_roll.global_transform = thigh_pose.global_transform
	
	var g := animator.gizmo
	
	if g:
		if g.controllable:
			g.global_transform = g.controllable.control_node.global_transform


func interpolate_keyframes():
	if anim_track_holder.keyframes.size() == 0:
		return
	if prev_keyframe_idx < 0 or next_keyframe_idx < 0:
		prev_keyframe_idx = 0
		next_keyframe_idx = 0
	
	var t : float
	t = get_t_from_keyframes(anim_track_holder.time)
	var animator_1 := prev_keyframe.animator as FootAnimator
	var animator_2 := next_keyframe.animator as FootAnimator
	
	
	animator_1.pelvis.global_transform = spine_bone_modifier.interpolate_pelvis_in_time(prev_keyframe.time)
	animator_2.pelvis.global_transform = spine_bone_modifier.interpolate_pelvis_in_time(next_keyframe.time)
	
	
	var foot_offset := get_skeleton().get_bone_global_rest(foot_id).basis as Quaternion
	
	var thigh_pos_1 := thigh_offset_to_pelvis
	var thigh_pos_2 := thigh_offset_to_pelvis
	
	animator_1.thigh_pose.position = thigh_pos_1
	animator_1.thigh_tangent.position = Vector3.ZERO
	animator_2.thigh_pose.position = thigh_pos_2
	animator_2.thigh_tangent.position = Vector3.ZERO
	
	match animator_1.interp_mode:
		FootAnimator.InterpMode.IK_HERMITE:
			#TODO: curve interp
			var tr1 := animator_1.foot_ik_pose.global_transform
			var tr2 := animator_2.foot_ik_pose.global_transform
			#var _tr := tr1.interpolate_with(tr2, t)
			var pos := animator_1.foot_ik_pose.global_position.lerp(animator_2.foot_ik_pose.global_position, t)
			var spine_pos := spine_bone_modifier.interpolate_pelvis_in_time(anim_track_holder.time)
			await spine_bone_modifier.modification_processed
			var thigh_pos := get_skeleton().get_bone_global_pose(thigh_id).origin
			var roll := lerp_angle(animator_1.foot_ik_pose_roll.rotation.y, animator_2.foot_ik_pose_roll.rotation.y, t)
			var rots := IkInterpstatic.get_ik_interpolation(thigh_pos, pos, animator_1.thigh_length, animator_1.shin_length, roll)
			var pelvis_basis := spine_pos.basis
			var r_t := (pelvis_basis.inverse() as Quaternion) * rots[0]
			thigh_rot_setter.rot = r_t
			var r_s := rots[1]
			shin_rot_setter.rot = r_s
			var r_f := rots[1].inverse() * rots[0].inverse() * (tr1.basis.get_rotation_quaternion().slerp(tr2.basis.get_rotation_quaternion(), t) * foot_offset)
			foot_rot_setter.rot = r_f
		FootAnimator.InterpMode.CONSTANT:
			var rt := Quaternion.from_euler(animator_1.thigh_pose.rotation)
			thigh_rot_setter.rot = rt
			var rs := Quaternion.from_euler(animator_1.shin_pose.rotation)
			shin_rot_setter.rot = rs
			var rf := Quaternion.from_euler(animator_1.foot_pose.rotation) * foot_offset
			foot_rot_setter.rot = rf
		FootAnimator.InterpMode.FK_HERMITE:
			var r00 := Quaternion.from_euler(animator_1.thigh_pose.rotation)
			var r01 := Quaternion.from_euler(animator_2.thigh_pose.rotation)
			
			

			var r00t := Quaternion.from_euler(animator_1.thigh_tangent.rotation)
			var r01t := Quaternion.from_euler(animator_2.thigh_tangent.rotation)
			
			var axis_00 := (r00t).get_axis().normalized()
			var v00 := animator_1.thigh_angular_velocity
			
		
			
			var axis_01 := (r01t).get_axis().normalized()
			var v01 := animator_2.thigh_angular_velocity
			
			#var qt00 := r00 * Quaternion(axis_00, angle_00)
			#var qt01 := r01 * Quaternion(axis_01, angle_01)
			#
			var dur := next_keyframe.time - prev_keyframe.time
			var r0 := QuaternionExtender.my_quat_interpolate(r00, axis_00, v00, r01, axis_01, v01, t, dur, animator_2.thigh_rot_curve.baked_points)
			
			
			thigh_rot_setter.rot = r0
			
			var r10 := Quaternion.from_euler(animator_1.shin_pose.rotation)
			var r11 := Quaternion.from_euler(animator_2.shin_pose.rotation)
			
			var r10t := Quaternion.from_euler(animator_1.shin_tangent.rotation)
			var r11t := Quaternion.from_euler(animator_2.shin_tangent.rotation)
			
			var axis_10 := (r10t).get_axis().normalized()
			var v10 := animator_1.shin_angular_velocity
			
			var axis_11 := (r11t).get_axis().normalized()
			var v11 := animator_2.shin_angular_velocity
			
			var r1 := QuaternionExtender.my_quat_interpolate(r10, axis_10, v10, r11, axis_11, v11, t, dur, animator_2.shin_rot_curve.baked_points)
			
			shin_rot_setter.rot = r1
			
			var r20 := Quaternion.from_euler(animator_1.foot_pose.rotation)
			var r21 := Quaternion.from_euler(animator_2.foot_pose.rotation)
			var r20t := Quaternion.from_euler(animator_1.foot_tangent.rotation)
			var r21t := Quaternion.from_euler(animator_2.foot_tangent.rotation)
			
			var axis_20 := (r20t).get_axis().normalized()
			var v20 := animator_1.foot_angular_velocity
			
			var axis_21 := (r21t).get_axis().normalized()
			var v21 := animator_2.foot_angular_velocity
			
			var r2 := QuaternionExtender.my_quat_interpolate(r20, axis_20, v20, r21, axis_21, v21, t, dur, animator_2.foot_rot_curve.baked_points)
			r2 = r2 * foot_offset
			foot_rot_setter.rot = r2
