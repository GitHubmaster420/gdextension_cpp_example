## Always applied after auto lerp layer
@tool
class_name AutoHermiteLayer
extends HermiteLayer

func _init() -> void:
	index = 1
	use_hermite_origin = false

func compute_tangent(frame: int, keys: Array[int]) -> Vector3:
	var idx := keys.find(frame)
	if idx == -1:
		return Vector3.ZERO
	
	var has_prev := idx > 0
	var has_next := idx < keys.size() - 1
	
	if not has_prev and not has_next:
		return Vector3.ZERO
	
	var curr_q := transforms[frame].basis.get_rotation_quaternion()
	
	# One-sided cases
	if not has_prev:
		var next_key := keys[idx + 1]
		return _angular_velocity_between(frame, next_key)
	
	if not has_next:
		var prev_key := keys[idx - 1]
		return _angular_velocity_between(prev_key, frame)
	
	# Two-sided case
	var prev_key := keys[idx - 1]
	var next_key := keys[idx + 1]
	
	var w_prev := _angular_velocity_between(prev_key, frame)
	var w_next := _angular_velocity_between(frame, next_key)
	
	# Compare direction + magnitude agreement
	var agreement := w_prev.normalized().dot(w_next.normalized())
	
	# If directions agree sufficiently → smooth average
	if agreement > 0.5:
		return (w_prev + w_next) * 0.5
	
	# Otherwise pick the smaller magnitude (likely the non-spike)
	if w_prev.length() < w_next.length():
		return w_prev
	else:
		return w_next

func _angular_velocity_between(f1: int, f2: int) -> Vector3:
	if not transforms.has(f1) or not transforms.has(f2):
		return Vector3.ZERO
	
	var q1 := transforms[f1].basis.get_rotation_quaternion()
	var q2 := transforms[f2].basis.get_rotation_quaternion()
	
	var dt := absf(f2 - f1) / AnimPlayerModifier.FPS
	if dt <= 0.0:
		return Vector3.ZERO
	
	return AnimTrack.angular_velocity([q1, q2], dt)

func interpolate(t : float) -> Transform3D:
	var info := get_interpolation_info(t)
	var start_frame:= info.x
	var end_frame:= info.y
	var relative_t := info.z
	var before_start : int = int(INF)
	var after_start : int = int(-INF)
	
	var keys : Array[int]
	keys.assign(transforms.keys())
	keys.sort()

	var w1 := compute_tangent(int(start_frame), keys)
	var w2 := compute_tangent(int(end_frame), keys)

	
	var t1 := transforms[int(start_frame)]
	var t2 := transforms[int(end_frame)]
	
	var basis := AnimTrack.hermite_cubic_rotation(t1.basis, w1, t2.basis, w2, (end_frame - start_frame) / AnimPlayerModifier.FPS, relative_t)
	
	var origin : Vector3
	
	if use_hermite_origin:
		var v1 := previous_layer.get_velocity(start_frame / AnimPlayerModifier.FPS)
		var v2 := previous_layer.get_velocity(end_frame / AnimPlayerModifier.FPS)
		
		origin = AnimTrack.hermite_cubic_v3(t1.origin, v1, t2.origin, v2, (end_frame - start_frame) / AnimPlayerModifier.FPS, relative_t)
	else:
		origin = t1.origin.lerp(t2.origin, relative_t)
	
	return Transform3D(basis, origin)
