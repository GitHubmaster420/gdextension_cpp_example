extends Node
class_name QuaternionExtender

static func bezier_quat(q1 : Quaternion, q2 : Quaternion, q3 : Quaternion, q4 : Quaternion, t : float) -> Quaternion:
	return squad(q1, q2, q3, q4, t)

static func squad(a : Quaternion, cp_a : Quaternion, cp_b : Quaternion, b : Quaternion,  t : float ) -> Quaternion:

	return a.spherical_cubic_interpolate(b, cp_a, cp_b, t)

static func squad_in_time(a : Quaternion, post_a : Quaternion, post_b : Quaternion, b : Quaternion, t : float, b_t: float, pre_a_t: float, post_b_t: float) -> Quaternion:
	var diff := a.inverse() * post_a
	var pre_a := a * diff.inverse()
	return a.spherical_cubic_interpolate_in_time(b, pre_a, post_b, t, b_t, pre_a_t, post_b_t)

static func squad_with_vel(a : Quaternion, post_a_vel_relative : Vector3, b : Quaternion, post_b_vel_relative : Vector3, current_time : float, duration : float) -> Quaternion:
	var pre_a := a * Quaternion(-post_a_vel_relative.normalized(), post_a_vel_relative.length() * duration / 3.0)
	var post_b := b * Quaternion(post_b_vel_relative.normalized(), post_b_vel_relative.length() * duration / 3.0)
	var t := current_time / duration
	return a.spherical_cubic_interpolate(b, pre_a, post_b, t)

static func squad_in_time_with_vel(a : Quaternion, post_a_vel_relative : Vector3, b : Quaternion, post_b_vel_relative : Vector3, current_time : float, duration : float, b_t: float, pre_a_t: float, post_b_t: float) -> Quaternion:
	var pre_a := a * Quaternion(-post_a_vel_relative.normalized(), post_a_vel_relative.length() * duration * pre_a_t / 3.0)
	var post_b := b * Quaternion(post_b_vel_relative.normalized(), post_b_vel_relative.length() * duration * post_b_t / 3.0)
	var t := current_time / duration
	return a.spherical_cubic_interpolate_in_time(b, pre_a, post_b, t, b_t, pre_a_t, post_b_t)
