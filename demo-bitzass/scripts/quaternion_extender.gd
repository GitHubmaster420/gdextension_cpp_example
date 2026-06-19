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

static func my_quat_interpolate(q1 : Quaternion, ax1 : Vector3, infl1 : float, v1 : float, q2 : Quaternion, ax2 : Vector3, infl2 : float, v2 : float, t : float, dur : float) -> Quaternion:
	
	var angle_1 := v1 * dur * minf(t, infl1)
	
	angle_1 = clampf(angle_1, 0, PI - 0.0001)
	
	var quat_1 := q1 * Quaternion(ax1, angle_1)
	
	var angle_2 := v2 * dur * minf(1.0 - t, infl2)
	
	angle_2 = clampf(angle_2, 0, PI - 0.001)
	
	var quat_2 := q2 * Quaternion(ax2, -angle_2)
	
	return quat_1.slerp(quat_2, smoothstep(0, 1, t))
	
