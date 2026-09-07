@tool
extends BakedAnimator
class_name BakedHandAnimator

@export var ik_roll : float
@export var ik_hand_transform : Transform3D

var ik_roll_override : float
var ik_hand_pos_override : Vector3
var ik_hand_quat_override : Quaternion

@export var ik_roll_modifiers : Array[FloatModifier]
@export var ik_pos_modifiers : Array[VectorModifier]
@export var ik_quat_modifiers : Array[QuaternionModifier]

@export var shoulder_quat : Quaternion
@export var up_arm_quat : Quaternion
@export var fore_arm_quat : Quaternion
@export var hand_quat : Quaternion

var shoulder_quat_override : Quaternion
var up_arm_quat_override: Quaternion
var fore_arm_quat_override : Quaternion
var hand_quat_override : Quaternion

@export var shoulder_quat_modifiers : Array[QuaternionModifier]
@export var up_arm_quat_modifiers : Array[QuaternionModifier]
@export var fore_arm_quat_modifiers : Array[QuaternionModifier]
@export var hand_quat_modifiers : Array[QuaternionModifier]

@export var shoulder_tangent_vector : Vector3
@export var shoulder_tangent_magnitude : float

var shoulder_tangent_vector_override : Vector3
var shoulder_tangent_magnitude_override : float

@export var up_arm_tangent_vector : Vector3
@export var up_arm_tangent_magnitude : float

var up_arm_tangent_vector_override : Vector3
var up_arm_tangent_magnitude_override : float


@export var fore_arm_tangent_vector : Vector3
@export var fore_arm_tangent_magnitude : float

var fore_arm_tangent_vector_override : Vector3
var fore_arm_tangent_magnitude_override : float

@export var hand_tangent_vector : Vector3
@export var hand_tangent_magnitude : float

var hand_tangent_vector_override : Vector3
var hand_tangent_magnitude_override : float



@export var shoulder_tangent_vector_modifiers : Array[VectorModifier]
@export var up_arm_tangent_vector_modifiers : Array[VectorModifier]
@export var fore_arm_tangent_vector_modifiers : Array[VectorModifier]
@export var hand_tangent_vector_modifiers : Array[VectorModifier]

@export var shoulder_tangent_magnitude_modifiers : Array[FloatModifier]
@export var up_arm_tangent_magnitude_modifiers : Array[FloatModifier]
@export var fore_arm_tangent_magnitude_modifiers : Array[FloatModifier]
@export var hand_tangent_magnitude_modifiers : Array[FloatModifier]

@export var shoulder_ease_curve : MyEaseInOut
@export var up_arm_ease_curve : MyEaseInOut
@export var fore_arm_ease_curve : MyEaseInOut
@export var hand_ease_curve : MyEaseInOut

func modify_overrides(info_dic : Dictionary):
	ik_roll_override = ik_roll
	for m in ik_roll_modifiers:
		ik_roll = m.interpolate_float(ik_roll, info_dic)
	ik_hand_pos_override = ik_hand_transform.origin
	for m in ik_pos_modifiers:
		m.modify_variables(info_dic)
		ik_hand_pos_override = m.modify_vector(ik_hand_pos_override)
	ik_hand_quat_override = ik_hand_transform.basis.get_rotation_quaternion()
	for m in ik_quat_modifiers:
		m.modify_variables(info_dic)
		ik_hand_quat_override = m.modify_quaternion(ik_hand_quat_override)
	
	shoulder_quat_override = shoulder_quat
	for m in shoulder_quat_modifiers:
		m.modify_variables(info_dic)
		shoulder_quat_override = m.modify_quaternion(shoulder_quat_override)
	shoulder_tangent_vector_override = shoulder_tangent_vector_override
	for m in shoulder_tangent_vector_modifiers:
		m.modify_variables(info_dic)
		shoulder_tangent_vector_override = m.modify_vector(shoulder_tangent_vector_override)
	shoulder_tangent_magnitude_override = shoulder_tangent_magnitude
	for m in shoulder_tangent_magnitude_modifiers:
		shoulder_tangent_magnitude_override = m.interpolate_float(shoulder_tangent_magnitude, info_dic)
	
	up_arm_quat_override = up_arm_quat
	for m in up_arm_quat_modifiers:
		m.modify_variables(info_dic)
		up_arm_quat_override = m.modify_quaternion(up_arm_quat_override)
	up_arm_tangent_vector_override = up_arm_tangent_vector_override
	for m in up_arm_tangent_vector_modifiers:
		m.modify_variables(info_dic)
		up_arm_tangent_vector_override = m.modify_vector(up_arm_tangent_vector_override)
	up_arm_tangent_magnitude_override = up_arm_tangent_magnitude
	for m in up_arm_tangent_magnitude_modifiers:
		up_arm_tangent_magnitude_override = m.interpolate_float(up_arm_tangent_magnitude, info_dic)
	
	fore_arm_quat_override = fore_arm_quat
	for m in fore_arm_quat_modifiers:
		m.modify_variables(info_dic)
		fore_arm_quat_override = m.modify_quaternion(fore_arm_quat_override)
	fore_arm_tangent_vector_override = fore_arm_tangent_vector_override
	for m in fore_arm_tangent_vector_modifiers:
		m.modify_variables(info_dic)
		fore_arm_tangent_vector_override = m.modify_vector(fore_arm_tangent_vector_override)
	fore_arm_tangent_magnitude_override = fore_arm_tangent_magnitude
	for m in fore_arm_tangent_magnitude_modifiers:
		fore_arm_tangent_magnitude_override = m.interpolate_float(fore_arm_tangent_magnitude, info_dic)
	
	hand_quat_override = hand_quat
	for m in hand_quat_modifiers:
		m.modify_variables(info_dic)
		hand_quat_override = m.modify_quaternion(hand_quat_override)
	hand_tangent_vector_override = hand_tangent_vector_override
	for m in hand_tangent_vector_modifiers:
		m.modify_variables(info_dic)
		hand_tangent_vector_override = m.modify_vector(hand_tangent_vector_override)
	hand_tangent_magnitude_override = hand_tangent_magnitude
	for m in hand_tangent_magnitude_modifiers:
		hand_tangent_magnitude_override = m.interpolate_float(hand_tangent_magnitude, info_dic)
	
	
