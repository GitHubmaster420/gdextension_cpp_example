@tool
class_name BakedRootAnimator extends BakedAnimator

@export var root_transform : Transform3D
var root_override_pos : Vector3
var root_override_quat : Quaternion

@export var root_quat_modifiers : Array[QuaternionModifier]
@export var root_pos_modifiers : Array[VectorModifier]

@export var root_loc_vector : Vector3
@export var root_loc_magnitude : float
@export var root_loc_ease_curve : MyEaseInOut

@export var root_loc_vel_vector_modifiers : Array[VectorModifier]
@export var root_loc_vel_mag_modifiers : Array[FloatModifier]

var root_override_loc_vector : Vector3
var root_override_loc_magnitude : float

@export var root_rot_vector : Vector3
@export var root_rot_magnitude : float
@export var root_rot_ease_curve : MyEaseInOut

@export var root_rot_vel_vector_modifiers : Array[VectorModifier]
@export var root_rot_mag_modifiers : Array[FloatModifier]

var root_override_rot_vector : Vector3
var root_override_rot_magnitude : float

func modify_overrides(info_dic: Dictionary) -> void:
	# Root transform
	root_override_pos = root_transform.origin
	root_override_quat = root_transform.basis.get_rotation_quaternion()
	
	for m in root_quat_modifiers:
		m.modify_variables(info_dic)
		root_override_quat = m.modify_quaternion(root_override_quat)
	
	for m in root_pos_modifiers:
		m.modify_variables(info_dic)
		root_override_pos = m.modify_vector(root_override_pos)
	
	
	# Root location vector
	root_override_loc_vector = root_loc_vector
	
	for m in root_loc_vel_vector_modifiers:
		m.modify_variables(info_dic)
		root_override_loc_vector = m.modify_vector(root_override_loc_vector)
	
	
	# Root location magnitude
	root_override_loc_magnitude = root_loc_magnitude
	
	for m in root_loc_vel_mag_modifiers:
		root_override_loc_magnitude = m.interpolate_float(
			root_override_loc_magnitude,
			info_dic
		)
	
	
	# Root rotation vector
	root_override_rot_vector = root_rot_vector
	
	for m in root_rot_vel_vector_modifiers:
		m.modify_variables(info_dic)
		root_override_rot_vector = m.modify_vector(root_override_rot_vector)
	
	
	# Root rotation magnitude
	root_override_rot_magnitude = root_rot_magnitude
	
	for m in root_rot_mag_modifiers:
		root_override_rot_magnitude = m.interpolate_float(
			root_override_rot_magnitude,
			info_dic
		)

func get_rotation_quaternion() -> Quaternion:
	var q := root_transform.basis.get_rotation_quaternion()
	for m in root_quat_modifiers:
		q = m.modify_quaternion(q)
	return q
