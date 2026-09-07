@tool
extends Resource
class_name BakedAnimation

@export var right_foot_track_holder : BakedTrackHolder
@export var left_foot_track_holder : BakedTrackHolder

@export var right_hand_track_holder : BakedTrackHolder
@export var left_hand_track_holder : BakedTrackHolder

@export var spine_track_holder : BakedTrackHolder

@export var head_track_holder : BakedTrackHolder

@export var root_track_holder : BakedTrackHolder

@export var ball_pos : Vector3
@export var ball_launch_time : float
@export var ball_launch_vel : Vector3

@export var org_transforms_dic : Dictionary

@export_tool_button("fil org transforms dic") var d = fill_org_transforms_dic


func fill_org_transforms_dic():
	org_transforms_dic = {}
	org_transforms_dic["foot_ball_hit_t"] = (right_foot_track_holder.baked_animators[1] as BakedFootAnimator).ik_foot_transform
	org_transforms_dic["hip_ball_hit_pos"] = (right_foot_track_holder.baked_animators[1] as BakedFootAnimator).hip_pos
	
	org_transforms_dic["spine_root_ts"] = []
	org_transforms_dic["pelvis_quats"] = []
	org_transforms_dic["pelvis_locs"] = []
	for spine_animator : BakedSpineAnimator in spine_track_holder.baked_animators:
		(org_transforms_dic["spine_root_ts"] as Array).append(spine_animator.root_transform)
		(org_transforms_dic["pelvis_quats"] as Array).append(spine_animator.pelvis_transform.basis.get_rotation_quaternion())
		(org_transforms_dic["pelvis_locs"] as Array).append(spine_animator.pelvis_transform.origin)
	org_transforms_dic["right_shoulder_quats"] = []
	org_transforms_dic["right_up_arm_quats"] = []
	org_transforms_dic["right_fore_arm_quats"] = []
	org_transforms_dic["right_hand_quats"] = []
	for hand_animator : BakedHandAnimator in right_hand_track_holder.baked_animators:
		(org_transforms_dic["right_shoulder_quats"] as Array).append(hand_animator.shoulder_quat)
		(org_transforms_dic["right_up_arm_quats"] as Array).append(hand_animator.up_arm_quat)
		(org_transforms_dic["right_fore_arm_quats"] as Array).append(hand_animator.fore_arm_quat)
		(org_transforms_dic["right_hand_quats"] as Array).append(hand_animator.hand_quat)
	org_transforms_dic["left_shoulder_quats"] = []
	org_transforms_dic["left_up_arm_quats"] = []
	org_transforms_dic["left_fore_arm_quats"] = []
	org_transforms_dic["left_hand_quats"] = []
	for hand_animator : BakedHandAnimator in left_hand_track_holder.baked_animators:
		(org_transforms_dic["left_shoulder_quats"] as Array).append(hand_animator.shoulder_quat)
		(org_transforms_dic["left_up_arm_quats"] as Array).append(hand_animator.up_arm_quat)
		(org_transforms_dic["left_fore_arm_quats"] as Array).append(hand_animator.fore_arm_quat)
		(org_transforms_dic["left_hand_quats"] as Array).append(hand_animator.hand_quat)
	
	
