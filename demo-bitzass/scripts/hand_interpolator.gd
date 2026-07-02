@tool
extends BodyPartInterpolator
class_name HandInterpolator

@export var spine_interpolator : SpineBoneModifier

@export var chest_name : String:
	set(v):
		chest_name = v
		if not is_node_ready():
			return
		chest_idx = get_skeleton().find_bone(chest_name)
@export var chest_idx : int

var chest_rest : Transform3D

var arm_to_chest : Vector3

@export var up_arm_name : String:
	set(v):
		up_arm_name = v
		if not is_node_ready():
			return
		up_arm_idx = get_skeleton().find_bone(up_arm_name)
@export var up_arm_idx : int
@export var low_arm_name : String:
	set(v):
		low_arm_name = v
		if not is_node_ready():
			return
		low_arm_idx = get_skeleton().find_bone(low_arm_name)
@export var low_arm_idx : int
@export var hand_name : String:
	set(v):
		hand_name = v
		if not is_node_ready():
			return
		hand_idx = get_skeleton().find_bone(hand_name)
@export var hand_idx : int

@export var shoulder_rot_setter : BoneRotSetter
@export var up_arm_rot_setter : BoneRotSetter
@export var low_arm_rot_setter : BoneRotSetter
@export var hand_rot_setter : BoneRotSetter

func _validate_property(property: Dictionary) -> void:
	if property.name == "chest_name" or property.name == "up_arm_name" or property.name == "low_arm_name" or property.name == "hand_name":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()

@export var is_right_hand := true:
	set(v):
		is_right_hand = v
		if not is_node_ready():
			return
		anim_track_holder.is_right = is_right_hand

func _ready() -> void:
	up_arm_name = up_arm_name
	low_arm_name = low_arm_name
	hand_name = hand_name
	chest_name = chest_name
	chest_rest = get_skeleton().get_bone_global_rest(chest_idx)
	arm_to_chest = get_skeleton().get_bone_global_rest(up_arm_idx).origin - chest_rest.origin
	super()

func interpolate_keyframes():
	if anim_track_holder.keyframes.size() == 0:
		return
	if prev_keyframe_idx < 0 or next_keyframe_idx < 0:
		prev_keyframe_idx = 0
		next_keyframe_idx = 0
	var t := get_t_from_keyframes(anim_track_holder.time)
	var animator_1 := prev_keyframe.animator as HandsAnimator
	var animator_2 := next_keyframe.animator as HandsAnimator
	
	var animator_0 : HandsAnimator
	if prev_keyframe_idx == 0:
		animator_0 = prev_keyframe.animator
	else:
		animator_0 = animator_1
	var animator_3 : HandsAnimator
	if next_keyframe_idx == anim_track_holder.keyframes.size() - 1:
		animator_3 = animator_2
	else:
		animator_3 = anim_track_holder.keyframes[next_keyframe_idx + 1].animator
	
	var spine_1 := spine_interpolator.interpolate_chest_in_time(prev_keyframe.time)
	var spine_2 := spine_interpolator.interpolate_chest_in_time(next_keyframe.time)
	
	animator_1.chest.global_transform = spine_1
	animator_2.chest.global_transform = spine_2
	
	animator_1.shoulder_pose.position = get_skeleton().get_bone_rest(get_skeleton().get_bone_parent(up_arm_idx)).origin
	animator_2.shoulder_pose.position = get_skeleton().get_bone_rest(get_skeleton().get_bone_parent(up_arm_idx)).origin
	
	var chest_offset_1 := chest_rest.basis.inverse() * spine_1.basis as Quaternion
	var chest_offset_2 := chest_rest.basis.inverse() * spine_2.basis as Quaternion
	
	chest_offset_1 = chest_offset_1.inverse()
	chest_offset_2 = chest_offset_2.inverse()
	
	var r_up_arm_0 := Quaternion.from_euler(animator_1.up_arm_pose.rotation)
	var r_up_arm_1 := Quaternion.from_euler(animator_2.up_arm_pose.rotation)
	if animator_1.use_up_arm_auto_tangent:
		animator_1.up_arm_tangent = QuaternionExtender.get_auto_velocity_axis(animator_1.up_arm_pose.basis, animator_0.up_arm_pose.basis, animator_2.up_arm_pose.basis, (animator_1.up_arm_auto_influence + 1) / 2.0)
	if animator_2.use_up_arm_auto_tangent:
		animator_2.up_arm_tangent = QuaternionExtender.get_auto_velocity_axis(animator_2.up_arm_pose.basis, animator_1.up_arm_pose.basis, animator_3.up_arm_pose.basis, (animator_2.up_arm_auto_influence + 1) / 2.0)
	up_arm_rot_setter.rot = QuaternionExtender.my_quat_interpolate(r_up_arm_0, animator_1.up_arm_tangent, 1, animator_1.up_arm_angular_velocity, r_up_arm_1, animator_2.up_arm_tangent, 1, animator_2.up_arm_angular_velocity, t, next_keyframe.time - prev_keyframe.time, animator_2.up_arm_ease_curve.baked_points)
	
	var r_low_arm_0 := Quaternion.from_euler(animator_1.low_arm_pose.rotation)
	var r_low_arm_1 := Quaternion.from_euler(animator_2.low_arm_pose.rotation)
	if animator_1.use_low_arm_auto_tangent:
		animator_1.low_arm_tangent = QuaternionExtender.get_auto_velocity_axis(animator_1.low_arm_pose.basis, animator_0.low_arm_pose.basis, animator_2.low_arm_pose.basis, (animator_1.low_arm_auto_influence + 1) / 2.0)
	if animator_2.use_low_arm_auto_tangent:
		animator_2.low_arm_tangent = QuaternionExtender.get_auto_velocity_axis(animator_2.low_arm_pose.basis, animator_1.low_arm_pose.basis, animator_3.low_arm_pose.basis, (animator_2.low_arm_auto_influence + 1) / 2.0)
	low_arm_rot_setter.rot = QuaternionExtender.my_quat_interpolate(r_low_arm_0, animator_1.low_arm_tangent, 1, animator_1.low_arm_angular_velocity, r_low_arm_1, animator_2.low_arm_tangent, 1, animator_2.low_arm_angular_velocity, t, next_keyframe.time - prev_keyframe.time, animator_2.low_arm_ease_curve.baked_points)
	
	var r_hand_0 := Quaternion.from_euler(animator_1.hand_pose.rotation)
	var r_hand_1 := Quaternion.from_euler(animator_2.hand_pose.rotation)
	if animator_1.use_hand_auto_tagent:
		animator_1.hand_tangent = QuaternionExtender.get_auto_velocity_axis(animator_1.hand_pose.basis, animator_0.hand_pose.basis, animator_2.hand_pose.basis, (animator_1.hand_auto_influence + 1) / 2.0)
	if animator_2.use_hand_auto_tagent:
		animator_2.hand_tangent = QuaternionExtender.get_auto_velocity_axis(animator_2.hand_pose.basis, animator_1.hand_pose.basis, animator_3.hand_pose.basis, (animator_2.hand_auto_influence + 1) / 2.0)
	hand_rot_setter.rot = QuaternionExtender.my_quat_interpolate(r_hand_0, animator_1.hand_tangent, 1, animator_1.hand_angular_velocity, r_hand_1, animator_2.hand_tangent, 1, animator_2.hand_angular_velocity, t, next_keyframe.time - prev_keyframe.time, animator_2.hand_ease_curve.baked_points)
	
	
	

func on_keyframe_added(key : Keyframe):
	var animator := key.animator as HandsAnimator
	await get_skeleton().skeleton_updated
	var stored := animator.gizmo.controllable
	stored.gizmo = null
	animator.gizmo.controllable = null
	var shoulder_idx := get_skeleton().get_bone_parent(up_arm_idx)
	var shoulder_tr := get_skeleton().get_bone_pose(shoulder_idx)
	var up_arm_tr := get_skeleton().get_bone_pose(up_arm_idx)
	var low_arm_tr := get_skeleton().get_bone_pose(low_arm_idx)
	var hand_tr := get_skeleton().get_bone_pose(hand_idx)
	
	var chest_tr := get_skeleton().get_bone_global_pose(get_skeleton().get_bone_parent(shoulder_idx))
	animator.chest.global_transform = chest_tr
	
	animator.shoulder_pose.transform = shoulder_tr
	animator.up_arm_pose.transform = up_arm_tr
	animator.low_arm_pose.transform = low_arm_tr
	animator.hand_pose.transform = hand_tr
	animator.current = animator.current
	
	animator.request_auto_velocity.connect(calculate_auto_velocity.bind(key))

func calculate_auto_velocity(idx : int, kf : Keyframe):
	var caller := kf.animator as HandsAnimator
	var h := anim_track_holder
	var aks := h.keyframes
	var this := h.keyframes.find(kf)
	var prev_idx := this-1 if this > 0 else 0
	var next_idx := this + 1 if this < aks.size() - 1 else aks.size() - 1
	var prev_kf := aks[prev_idx]
	var next_kf := aks[next_idx]
	if prev_kf.time == next_kf.time:
		caller.set_aut_velocity(idx, 0)
		return
	var prev := aks[prev_idx].animator as HandsAnimator
	var next := aks[next_idx].animator as HandsAnimator
	var t := remap(kf.time, prev_kf.time, next_kf.time, 0, 1)
	# prev_q : Quaternion, prev_ax : Vector3, prev_infl : float, prev_v : float, next_q : Quaternion, next_ax : Vector3, next_infl : float, next_v : float, dur : float, next_points : PackedFloat32Array
	var prev_q : Quaternion
	var prev_ax : Vector3
	var prev_infl := 1
	var prev_v : float
	
	var next_q : Quaternion
	var next_ax : Vector3
	var next_infl := 1
	var next_v : float
	
	var ease_points : PackedFloat32Array
	
	match idx:
		0:
			prev_q = prev.up_arm_pose.basis
			prev_ax = prev.up_arm_tangent
			prev_v = prev.up_arm_angular_velocity
			next_q = next.up_arm_pose.basis
			next_ax = next.up_arm_tangent
			next_v = next.up_arm_angular_velocity
			ease_points = next.up_arm_ease_curve.baked_points
		1:
			prev_q = prev.low_arm_pose.basis
			prev_ax = prev.low_arm_tangent
			prev_v = prev.low_arm_angular_velocity
			next_q = next.low_arm_pose.basis
			next_ax = next.low_arm_tangent
			next_v = next.low_arm_angular_velocity
			ease_points = next.lo_arm_ease_curve.baked_points
			
		2:
			prev_q = prev.hand_pose.basis
			prev_ax = prev.hand_tangent
			prev_v = prev.hand_angular_velocity
			next_q = next.hand_pose.basis
			next_ax = next.hand_tangent
			next_v = next.hand_angular_velocity
			ease_points = next.hand_ease_curve.baked_points
			
	var mag := QuaternionExtender.get_auto_velocity(prev_q, prev_ax, prev_infl, prev_v, next_q, next_ax, next_infl, next_v, next_kf.time - prev_kf.time, ease_points)
	(kf.animator as HandsAnimator).set_aut_velocity(idx, mag)
		
	
func _process_modification_with_delta(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if anim_track_holder.keyframes.size() == 0:
		return
	on_time_changed(anim_track_holder.time)
	interpolate_keyframes()
