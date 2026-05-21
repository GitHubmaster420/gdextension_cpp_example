@tool
extends LerpLayer
class_name AutoLerpLayer

func generate_times(tracked_frames: Array[int], _transforms: Dictionary[int, Transform3D], threshold := 0.5) -> PackedInt32Array:
	
	var keep : Array[int]
	keep.assign(tracked_frames.duplicate())
	keep.sort()
	
	if keep.size() < 3:
		return keep
	
	var dt := 1.0 / AnimPlayerModifier.FPS
	
	while true:
		
		if keep.size() < 3:
			break
		
		# Step 1 — compute angular velocities (central difference)
		var w : Dictionary[int, Vector3]= {}
		
		for i in range(1, keep.size() - 1):
			var f_prev := keep[i - 1]
			var f_next := keep[i + 1]

			var q_prev := transforms[f_prev].basis.get_rotation_quaternion()
			var q_next := transforms[f_next].basis.get_rotation_quaternion()

			var frame_delta := f_next - f_prev
			var delta_time := frame_delta * dt

			var omega := angular_velocity_between(q_prev, q_next, delta_time)
			w[keep[i]] = omega
		
		# Step 2 — compute acceleration magnitude
		var worst_frame := -1
		var worst_value := 0.0
		
		for i in range(2, keep.size() - 2):
			var f0 := keep[i - 1]
			var f1 := keep[i]
			var f2 := keep[i + 1]
			
			if not (f0 in w and f1 in w and f2 in w):
				continue
			
			var dt_local := (f2 - f1) * dt
			var accel := (w[f2] - w[f1]).length() / dt_local
			
			if accel > worst_value:
				worst_value = accel
				worst_frame = f1
		
		# Step 3 — remove worst if above threshold
		if worst_value > threshold:
			keep.erase(worst_frame)
		else:
			break
	
	return keep

static func angular_velocity_between(q1: Quaternion, q2: Quaternion, delta_time: float) -> Vector3:
	var dq = q1.inverse() * q2
	dq = dq.normalized()
	
	var angle = 2.0 * acos(clamp(dq.w, -1.0, 1.0))
	
	if angle < 0.00001:
		return Vector3.ZERO
	
	var axis = Vector3(dq.x, dq.y, dq.z).normalized()
	
	return axis * (angle / delta_time)
