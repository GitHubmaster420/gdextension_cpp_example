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
	
	var r00 := Quaternion.from_euler(animator_1.up_arm_pose.rotation)
	var r01 := Quaternion.from_euler(animator_2.up_arm_pose.rotation)
	up_arm_rot_setter.rot = r00.slerp(r01, t)
	
	var r10 := Quaternion.from_euler(animator_1.low_arm_pose.rotation)
	var r11 := Quaternion.from_euler(animator_2.low_arm_pose.rotation)
	
	
	low_arm_rot_setter.rot = r10.slerp(r11, t)
	
	
	var r20 := Quaternion.from_euler(animator_1.hand_pose.rotation)
	var r21 := Quaternion.from_euler(animator_2.hand_pose.rotation)
	
	hand_rot_setter.rot = r20.slerp(r21, t)

func on_keyframe_added(key : Keyframe):
	var animator := key.animator as HandsAnimator
	await get_skeleton().skeleton_updated
	
	var shoulder_idx := get_skeleton().get_bone_parent(up_arm_idx)
	var shoulder_tr := get_skeleton().get_bone_global_pose(shoulder_idx)
	var up_arm_tr := get_skeleton().get_bone_global_pose(up_arm_idx)
	var low_arm_tr := get_skeleton().get_bone_global_pose(low_arm_idx)
	var hand_tr := get_skeleton().get_bone_global_pose(hand_idx)
	
	var chest_tr := get_skeleton().get_bone_global_pose(chest_idx)
	animator.chest.global_transform = chest_tr
	
	animator.shoulder_pose.global_transform = shoulder_tr
	animator.up_arm_pose.global_transform = up_arm_tr
	animator.low_arm_pose.global_transform = low_arm_tr
	animator.hand_pose.global_transform = hand_tr

func _process_modification_with_delta(_delta: float) -> void:
	interpolate_keyframes()
