extends Node
class_name HandJcAtt

@export var elbow_node : KinectJoint

func attach_joycon(jc : JoyCon):
	calibrate_joycon(jc)
	copy_modifier_pose.active = true
	copy_modifier_pose.target = jc
	jc.reference_basis = ref_basis_right if jc.is_right_joycon else ref_basis_left

func calibrate_joycon(jc : JoyCon):
	jc.joycon_basis = Basis.IDENTITY
	copy_modifier_pose.reference_basis = elbow_node.global_basis
	

func detatch_joycon():
	copy_modifier_pose.target = null

var ref_basis_right : Basis
var ref_basis_left : Basis

@export var reference_object : Marker3D

@export var copy_modifier_pose: CopyModifierPose

@export var kinect_joint : KinectJoint


func _ready() -> void:
	ref_basis_right = Basis.from_euler(reference_object.global_rotation)
	ref_basis_left = Basis.from_euler(reference_object.global_rotation * Basis.FLIP_X)
