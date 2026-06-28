extends Node
class_name MyCurve3D

static func interpolate(start : Vector3, v_start : Vector3, end : Vector3, v_end : Vector3, t : float, dur : float) -> Vector3:
	start = start + v_start * t * dur
	end = end - v_end * (1.0 - t) * dur
	return start.lerp(end, smoothstep(0, 1, t))

static func get_auto_tangent(this : Vector3, prev : Vector3, next : Vector3, t : float) -> Vector3:
	return (this- prev).lerp(next - this, t).normalized()

static func get_auto_velocity_amount(prev_loc : Vector3, prev_v : Vector3, next_loc : Vector3, next_v : Vector3, dur : float) -> float:
	var small_amount := 0.001
	var t := 0.5
	var t_plus := t + small_amount
	
	var vec_start := interpolate(prev_loc, prev_v, next_loc, next_v, t, dur)
	var vec_end := interpolate(prev_loc, prev_v, next_loc, next_v, t_plus, dur)
	
	return vec_start.distance_to(vec_end) / small_amount
