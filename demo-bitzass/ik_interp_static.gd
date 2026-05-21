extends Node3D
class_name IkInterpstatic

enum InterpMode{
	IK_LERP,
	FK_SLERP,
	FK_HERMITE
}

static func get_fk_slerp_interpolation(start_hip : Vector3, start_foot : Vector3,start_roll : float, end_hip : Vector3, end_foot : Vector3, end_roll : float, thigh_length : float, shin_length : float, t : float,thigh_curve : Curve = null, shin_curve : Curve = null) -> Array[Quaternion]:
	var start_ik := get_ik_interpolation(start_hip, start_foot, thigh_length, shin_length, start_roll)
	var end_ik := get_ik_interpolation(end_hip, end_foot, thigh_length, shin_length, end_roll)
	var thigh_t := t
	var shin_t := t
	if thigh_curve:
		thigh_t = thigh_curve.sample(thigh_t)
	if shin_curve:
		shin_t = shin_curve.sample(shin_t)
	var thigh_quat := start_ik[0].slerp(end_ik[0], thigh_t)
	var shin_quat := start_ik[1].slerp(end_ik[1], thigh_t)
	return [thigh_quat, shin_quat]

static func get_fk_hermite_interpolation(start_hip : Vector3, start_foot : Vector3, start_roll : float, start_thigh_tangent : Quaternion, start_shin_tangent : Quaternion, end_hip : Vector3, end_foot : Vector3, end_roll : float,end_thigh_tangent : Quaternion, end_shin_tangent : Quaternion, thigh_length : float, shin_length : float, t : float,thigh_curve : Curve = null, shin_curve : Curve = null) -> Array[Quaternion]:
	var ik1 := get_ik_interpolation(start_hip, start_foot, thigh_length, shin_length, start_roll)
	var ik2 := get_ik_interpolation(end_hip, end_foot, thigh_length, shin_length, end_roll)
	
	var thigh_start := ik1[0]
	var thigh_end := ik2[0]
	var shin_start := ik1[1]
	var shin_end := ik2[1]
	
	var thigh_quat := QuaternionExtender.bezier_quat(thigh_start, start_thigh_tangent, end_thigh_tangent, thigh_end, t)
	var shin_quat := QuaternionExtender.bezier_quat(shin_start, start_shin_tangent, end_shin_tangent, shin_end, t)
	
	return [thigh_quat, shin_quat]

static func get_ik_interpolation(origin : Vector3, target : Vector3, thigh_length : float, shin_length : float, roll : float) -> Array[Quaternion]:
	var to_target := target - origin
	var dir := to_target.normalized()
	var c := to_target.length()
	var a := thigh_length
	var b := shin_length
	var div := (b ** 2 + c ** 2 - a ** 2) / (2.0 * c * b)
	var angle := acos(div)
	
	if c > (a + b):
		angle = 0
	
	var rotate_around := Vector3(-cos(roll), 0, sin(roll))
	var tmp := rotate_around.cross(to_target).normalized()
	rotate_around = dir.cross(tmp).normalized()
	var thigh_dir := (dir).rotated(rotate_around, -angle)
	var knee_pos := origin + thigh_dir * a
	var shin_dir := (target - knee_pos).normalized()
	var right := thigh_dir.cross(dir).normalized()
	#TODO: edge case when straight
	
	if not right:
		right = Vector3.RIGHT
	
	var b1 : Basis
	
	b1.y = thigh_dir
	b1.z = right.cross(thigh_dir).normalized()
	b1.x = b1.y.cross(b1.z)
	
	var b2 : Basis
	b2.y = shin_dir
	b2.z = right.cross(shin_dir).normalized()
	b2.x = b2.y.cross(b2.z)
	
	var quat_1 := Quaternion(b1)
	var quat_2 := quat_1.inverse() * Quaternion(b2)
	
	
	return [
		quat_1,
		quat_2
	]

static func bake_hermite(start : Array[Quaternion], start_mid : Array[Quaternion], end_mid : Array[Quaternion], end : Array[Quaternion]):
	return[]
