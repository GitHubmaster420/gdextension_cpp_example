@tool
extends BakedAnimator
class_name BakedSpineAnimator

@export var root_transform : Transform3D

@export var pelvis_transform : Transform3D
@export var hip_quat : Quaternion
@export var chest_quat : Quaternion


@export var pelvis_quat_modifiers : Array[QuaternionModifier]
@export var hip_quat_modifiers : Array[QuaternionModifier]
@export var chest_quat_modifiers : Array[QuaternionModifier]


@export var pelvis_rot_tangent_vector : Vector3
@export var pelvis_rot_tangent_magnitude : float
@export var pelvis_rot_curve : MyEaseInOut

@export var hip_rot_tangent_vector : Vector3
@export var hip_rot_tangent_magnitude : float
@export var hip_rot_curve : MyEaseInOut

@export var chest_rot_tangent_vector : Vector3
@export var chest_rot_tangent_magnitude : float
@export var chest_rot_curve : MyEaseInOut


@export var pelvis_loc_tangent_vector : Vector3
@export var pelvis_loc_tangent_magnitude : float
@export var pelvis_loc_curve : MyEaseInOut


@export var pelvis_loc_modifiers : Array[VectorModifier]

@export var pelvis_rot_tangent_vector_modifiers : Array[VectorModifier]
@export var pelvis_rot_tangent_magnitude_modifiers : Array[FloatModifier]

@export var hip_rot_tangent_vector_modifiers : Array[VectorModifier]
@export var hip_rot_tangent_magnitude_modifiers : Array[FloatModifier]

@export var chest_rot_tangent_vector_modifiers : Array[VectorModifier]
@export var chest_rot_tangent_magnitude_modifiers : Array[FloatModifier]

@export var pelvis_loc_tangent_vector_modifiers : Array[VectorModifier]
@export var pelvis_loc_tangent_magnitude_modifiers : Array[FloatModifier]


var pelvis_override_pos : Vector3
var pelvis_override_quat : Quaternion

var hip_override_quat : Quaternion
var chest_override_quat : Quaternion

var pelvis_override_rot_tangent_vector : Vector3
var pelvis_override_rot_tangent_magnitude : float

var hip_override_rot_tangent_vector : Vector3
var hip_override_rot_tangent_magnitude : float

var chest_override_rot_tangent_vector : Vector3
var chest_override_rot_tangent_magnitude : float

var pelvis_override_loc_tangent_vector : Vector3
var pelvis_override_loc_tangent_magnitude : float


func modify_overrides(info_dic : Dictionary) -> void:
	# Pelvis transform
	pelvis_override_pos = pelvis_transform.origin
	pelvis_override_quat = pelvis_transform.basis.get_rotation_quaternion()
	
	for m in pelvis_quat_modifiers:
		m.modify_variables(info_dic)
		pelvis_override_quat = m.modify_quaternion(pelvis_override_quat)
	
	for m in pelvis_loc_modifiers:
		m.modify_variables(info_dic)
		pelvis_override_pos = m.modify_vector(pelvis_override_pos)
	
	
	# Hip quaternion
	hip_override_quat = hip_quat
	
	for m in hip_quat_modifiers:
		m.modify_variables(info_dic)
		hip_override_quat = m.modify_quaternion(hip_override_quat)
	
	
	# Chest quaternion
	chest_override_quat = chest_quat
	
	for m in chest_quat_modifiers:
		m.modify_variables(info_dic)
		chest_override_quat = m.modify_quaternion(chest_override_quat)
	
	
	# Pelvis rotation tangent vector
	pelvis_override_rot_tangent_vector = pelvis_rot_tangent_vector
	
	for m in pelvis_rot_tangent_vector_modifiers:
		m.modify_variables(info_dic)
		pelvis_override_rot_tangent_vector = m.modify_vector(
			pelvis_override_rot_tangent_vector
		)
	
	
	# Pelvis rotation tangent magnitude
	pelvis_override_rot_tangent_magnitude = pelvis_rot_tangent_magnitude
	
	for m in pelvis_rot_tangent_magnitude_modifiers:
		pelvis_override_rot_tangent_magnitude = m.interpolate_float(
			pelvis_override_rot_tangent_magnitude,
			info_dic
		)
	
	
	# Hip rotation tangent vector
	hip_override_rot_tangent_vector = hip_rot_tangent_vector
	
	for m in hip_rot_tangent_vector_modifiers:
		m.modify_variables(info_dic)
		hip_override_rot_tangent_vector = m.modify_vector(
			hip_override_rot_tangent_vector
		)
	
	
	# Hip rotation tangent magnitude
	hip_override_rot_tangent_magnitude = hip_rot_tangent_magnitude
	
	for m in hip_rot_tangent_magnitude_modifiers:
		hip_override_rot_tangent_magnitude = m.interpolate_float(
			hip_override_rot_tangent_magnitude,
			info_dic
		)
	
	
	# Chest rotation tangent vector
	chest_override_rot_tangent_vector = chest_rot_tangent_vector
	
	for m in chest_rot_tangent_vector_modifiers:
		m.modify_variables(info_dic)
		chest_override_rot_tangent_vector = m.modify_vector(
			chest_override_rot_tangent_vector
		)
	
	
	# Chest rotation tangent magnitude
	chest_override_rot_tangent_magnitude = chest_rot_tangent_magnitude
	
	for m in chest_rot_tangent_magnitude_modifiers:
		chest_override_rot_tangent_magnitude = m.interpolate_float(
			chest_override_rot_tangent_magnitude,
			info_dic
		)
	
	
	# Pelvis location tangent vector
	pelvis_override_loc_tangent_vector = pelvis_loc_tangent_vector
	
	for m in pelvis_loc_tangent_vector_modifiers:
		m.modify_variables(info_dic)
		pelvis_override_loc_tangent_vector = m.modify_vector(
			pelvis_override_loc_tangent_vector
		)
	
	
	# Pelvis location tangent magnitude
	pelvis_override_loc_tangent_magnitude = pelvis_loc_tangent_magnitude
	
	for m in pelvis_loc_tangent_magnitude_modifiers:
		pelvis_override_loc_tangent_magnitude = m.interpolate_float(
			pelvis_override_loc_tangent_magnitude,
			info_dic
		)
