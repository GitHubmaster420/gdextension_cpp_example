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

func _process_modification() -> void:
	interpolate_keyframes()

func on_keyframe_added(key : Keyframe):
	await get_skeleton().skeleton_updated
	var animator := key.animator as FootAnimator
	var tt := get_skeleton().get_bone_global_pose(thigh_id)
	var st := get_skeleton().get_bone_global_pose(shin_id)
	var foot_offset := get_skeleton().get_bone_global_rest(foot_id).basis.inverse()
	var ft := get_skeleton().get_bone_global_pose(foot_id)
	ft.basis = foot_offset * ft.basis
	animator.thigh_length = tt.origin.distance_to(st.origin)
	animator.shin_length = st.origin.distance_to(ft.origin)
	var thigh_pose := animator.thigh_pose
	thigh_pose.global_transform = tt
	var shin_pose := animator.shin_pose
	shin_pose.global_transform = st
	
	var foot_pose := animator.foot_pose
	foot_pose.global_transform = ft
	var foot_ik_pose := animator.foot_ik_pose
	foot_ik_pose.global_transform = ft
	thigh_rot_setter.global_transform = tt



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
	
	var spine_1 := spine_bone_modifier.interpolate_pelvis_in_time(prev_keyframe.time)
	var spine_2 := spine_bone_modifier.interpolate_pelvis_in_time(next_keyframe.time)
	
	var thigh_pos_1 := spine_1 * Transform3D(pelvis_rest.basis.inverse()) * thigh_offset_to_pelvis
	var thigh_pos_2 := spine_2 * Transform3D(pelvis_rest.basis.inverse()) * thigh_offset_to_pelvis
	
	animator_1.thigh_pose.global_position = thigh_pos_1
	animator_1.thigh_tangent.global_position = thigh_pos_1
	animator_2.thigh_pose.global_position = thigh_pos_2
	animator_2.thigh_tangent.global_position = thigh_pos_2
	
	var thigh_offset := (get_skeleton().get_bone_global_rest(thigh_id).basis as Quaternion).inverse() * (get_skeleton().get_bone_rest(thigh_id).basis as Quaternion)
	
	var pelvis_offset_1 := pelvis_rest.basis.inverse() * spine_1.basis as Quaternion
	var pelvis_offset_2 := pelvis_rest.basis.inverse() * spine_2.basis as Quaternion
	
	pelvis_offset_1 = pelvis_offset_1.inverse()
	pelvis_offset_2 = pelvis_offset_2.inverse()
	
	var r00 := pelvis_offset_1 * thigh_offset * Quaternion.from_euler(animator_1.thigh_pose.rotation)
	var r01 := pelvis_offset_2 * thigh_offset  * Quaternion.from_euler(animator_2.thigh_pose.rotation)
	thigh_rot_setter.rot = r00.slerp(r01, t)
	
	var r10 := Quaternion.from_euler(animator_1.shin_pose.rotation)
	var r11 := Quaternion.from_euler(animator_2.shin_pose.rotation)
	
	
	shin_rot_setter.rot = r10.slerp(r11, t)
	
	var foot_offset := get_skeleton().get_bone_global_rest(foot_id).basis as Quaternion
	
	var r20 := Quaternion.from_euler(animator_1.foot_pose.rotation) * foot_offset
	var r21 := Quaternion.from_euler(animator_2.foot_pose.rotation) * foot_offset
	
	foot_rot_setter.rot = r20.slerp(r21, t)
	
