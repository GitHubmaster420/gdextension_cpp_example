@tool
class_name BakedFootAnimator extends BakedAnimator

@export var is_on_ground : bool

@export var supports_ball_contact := false
@export var after_ball_contact := false

@export var hip_pos : Vector3

enum InterpMode{
	CONSTANT,
	FK_HERMITE,
	IK
}

@export var interp_mode : InterpMode

enum Parent{
	ROOT,
	SPINE,
	PREV_ANIMATOR
}

@export var parent := Parent.SPINE

@export var ik_roll : float
@export var ik_foot_transform : Transform3D

var ik_roll_override : float
var ik_foot_transform_override : Transform3D

@export var ik_roll_modifiers : Array[FloatModifier]
@export var ik_quat_modifiers : Array[QuaternionModifier]
@export var ik_pos_modifiers : Array[VectorModifier]

@export var thigh_quat : Quaternion
@export var shin_quat : Quaternion
@export var foot_quat : Quaternion

var thigh_quat_override : Quaternion
var shin_quat_override : Quaternion
var foot_quat_override : Quaternion

@export var thigh_quat_modifiers : Array[QuaternionModifier]
@export var shin_quat_modifiers : Array[QuaternionModifier]
@export var foot_quat_modifiers : Array[QuaternionModifier]

@export var thigh_tangent_vector : Vector3
@export var thigh_tangent_magnitude : float


var thigh_tangent_vector_override : Vector3
var thigh_tangent_magnitude_override : float

@export var thigh_tangent_vector_modifiers : Array[VectorModifier]
@export var thigh_tangent_magnitude_modifiers : Array[FloatModifier]


@export var shin_tangent_vector : Vector3
@export var shin_tangent_magnitude : float

var shin_tangent_vector_override : Vector3
var shin_tangent_magnitude_override : float

@export var shin_tangent_vector_modifiers : Array[VectorModifier]
@export var shin_tangent_magnitude_modifiers : Array[FloatModifier]

@export var foot_tangent_vector : Vector3
@export var foot_tangent_magnitude : float

var foot_tangent_vector_override : Vector3
var foot_tangent_magnitude_override : float

@export var foot_tangent_vector_modifiers : Array[VectorModifier]
@export var foot_tangent_magnitude_modifiers : Array[FloatModifier]

@export var thigh_ease_curve : MyEaseInOut
@export var shin_ease_curve : MyEaseInOut
@export var foot_ease_curve : MyEaseInOut

func modify_overrides(info_dic : Dictionary) -> void:
	# IK roll
	ik_roll_override = ik_roll
	for m in ik_roll_modifiers:
		ik_roll_override = m.interpolate_float(ik_roll_override, info_dic)
	
	
	# IK foot transform
	ik_foot_transform_override = ik_foot_transform
	
	for m in ik_quat_modifiers:
		m.modify_variables(info_dic)
		var q := ik_foot_transform_override.basis.get_rotation_quaternion()
		ik_foot_transform_override.basis = m.modify_quaternion(q) as Basis
	
	for m in ik_pos_modifiers:
		m.modify_variables(info_dic)
		var pos := ik_foot_transform_override.origin
		ik_foot_transform_override.origin = m.modify_vector(pos)
	
	
	# Thigh quaternion
	thigh_quat_override = thigh_quat
	for m in thigh_quat_modifiers:
		m.modify_variables(info_dic)
		thigh_quat_override = m.modify_quaternion(thigh_quat_override)
	
	
	# Shin quaternion
	shin_quat_override = shin_quat
	for m in shin_quat_modifiers:
		m.modify_variables(info_dic)
		shin_quat_override = m.modify_quaternion(shin_quat_override)
	
	
	# Foot quaternion
	foot_quat_override = foot_quat
	for m in foot_quat_modifiers:
		m.modify_variables(info_dic)
		foot_quat_override = m.modify_quaternion(foot_quat_override)
	
	
	# Thigh tangent vector
	thigh_tangent_vector_override = thigh_tangent_vector
	for m in thigh_tangent_vector_modifiers:
		m.modify_variables(info_dic)
		thigh_tangent_vector_override = m.modify_vector(thigh_tangent_vector_override)
	
	# Thigh tangent magnitude
	thigh_tangent_magnitude_override = thigh_tangent_magnitude
	for m in thigh_tangent_magnitude_modifiers:
		thigh_tangent_magnitude_override = m.interpolate_float(
			thigh_tangent_magnitude_override,
			info_dic
		)
	
	
	# Shin tangent vector
	shin_tangent_vector_override = shin_tangent_vector
	for m in shin_tangent_vector_modifiers:
		m.modify_variables(info_dic)
		shin_tangent_vector_override = m.modify_vector(shin_tangent_vector_override)
	
	# Shin tangent magnitude
	shin_tangent_magnitude_override = shin_tangent_magnitude
	for m in shin_tangent_magnitude_modifiers:
		shin_tangent_magnitude_override = m.interpolate_float(
			shin_tangent_magnitude_override,
			info_dic
		)
	
	
	# Foot tangent vector
	foot_tangent_vector_override = foot_tangent_vector
	for m in foot_tangent_vector_modifiers:
		m.modify_variables(info_dic)
		foot_tangent_vector_override = m.modify_vector(foot_tangent_vector_override)
	
	# Foot tangent magnitude
	foot_tangent_magnitude_override = foot_tangent_magnitude
	for m in foot_tangent_magnitude_modifiers:
		foot_tangent_magnitude_override = m.interpolate_float(
			foot_tangent_magnitude_override,
			info_dic
		)
