class_name AnimTrack extends Resource


@export var current_frame : int

@export var transforms : Array[Transform3D]

@export var keyframe_times : Array[float]

@export var origin_velocities : Dictionary[int, Vector3] #Optional, used for hermite interpolation

@export var angular_w_velocities : Dictionary[int, Vector3] #

@export var rotation_tangents : Dictionary[int, Quaternion]

enum BasisInterpType{
	QUAT_SLERP,
	HERMITE_CUBIC
}

@export var basis_interp_types : Array[BasisInterpType]

enum OriginInterpType{
	LERP,
	HERMITE_CUBIC,
	SLERP
}

@export var origin_interp_types : Array[OriginInterpType]

@export var interp_curves : Array[Curve]

func add_keyframe(transform : Transform3D, origin_type : OriginInterpType, basis_type : BasisInterpType, time : float, curve : Curve = null, velocity := Vector3.INF):
	transforms.append(transform)
	if velocity != Vector3.INF:
		origin_velocities[keyframe_times.size()] = velocity
	keyframe_times.append(time)
	if transforms.size() == 1:
		return
	basis_interp_types.append(basis_type)
	origin_interp_types.append(origin_type)
	interp_curves.append(curve)

func slerp_quats(b1 : Basis, b2 : Basis, t) -> Basis:
	return Quaternion(b1).slerp(b2, t)

func squad(qs : Quaternion, qe : Quaternion, ts : Quaternion, te : Quaternion, t : float):
	var s1 := qs.slerp(qe, t)
	var s2 := ts.slerp(te, t)
	return s1.slerp(s2, 2.0 * t * (1.0 - t))

func angular_velocity(quats: Array[Quaternion], dt: float) -> Vector3:
	if quats.size() < 2 or dt <= 0.0:
		return Vector3.ZERO

	var vs := []

	for i in range(quats.size() - 1):
		var q1 := quats[i]
		var q2 := quats[i+1]

		# relative rotation
		var dq := q1.inverse() * q2

		# shortest path
		if dq.w < 0.0:
			dq = -dq

		vs.append(quat_log(dq))

	# simple linear average in tangent space
	var avg = Vector3.ZERO
	for vec in vs:
		avg += vec
	avg /= vs.size()

	return (avg * 2.0) / dt

func quat_log(q: Quaternion) -> Vector3:
	var v = Vector3(q.x, q.y, q.z)
	var v_len = v.length()
	if v_len < 1e-8:
		return Vector3.ZERO
	var angle = atan2(v_len, q.w)
	return v.normalized() * angle

func quat_exp(v: Vector3) -> Quaternion:
	var angle = v.length()
	if angle < 1e-8:
		return Quaternion(0, 0, 0, 1)
	var axis = v / angle
	return Quaternion(axis * sin(angle), cos(angle))

func hermite_cubic_rotation(q1: Quaternion, w1: Vector3, q2: Quaternion, w2: Vector3, dt: float, t: float) -> Quaternion:
	# Compute tangent quaternions from angular velocities
	# The factor 0.5 comes from quaternion log conventions
	var a := q1 * quat_exp(-0.25 * w1 * dt)
	var b := q2 * quat_exp(0.25 * w2 * dt)

	# SQUAD-style blending
	var s1 := q1.slerp(q2, t)
	var s2 := a.slerp(b, t)
	return s1.slerp(s2, 2.0 * t * (1.0 - t)).normalized()

func hermite_cubic_v3(o1 : Vector3, v1 : Vector3, o2 : Vector3, v2 : Vector3, d : float, t) -> Vector3:
	var cp_1 := o1 + v1 * d
	var cp_2 := o2 - v2 * d
	return o1.bezier_interpolate(cp_1, cp_2, o2, t)



func interpolate_transforms(time : float) -> Transform3D:
	if transforms.size() == 0:
		return Transform3D()
	if transforms.size() == 1:
		return transforms[0]
	var next_idx : int = 0
	var previous_idx : int = 0
	var t : float = 0.0
	for i in range(keyframe_times.size()):
		if time > keyframe_times[i]:
			next_idx = i + 1
			previous_idx = next_idx - 1
			t = (time - keyframe_times[previous_idx]) / (keyframe_times[next_idx] - keyframe_times[previous_idx])
			break
	t = clampf(t, 0, 1)
	if interp_curves[previous_idx]:
		t = interp_curves[previous_idx].sample(t)
	var trns := Transform3D()
	
	match basis_interp_types[previous_idx]:
		BasisInterpType.QUAT_SLERP:
			trns.basis = slerp_quats(transforms[previous_idx].basis, transforms[next_idx].basis, t)
		BasisInterpType.HERMITE_CUBIC:
			trns.basis = hermite_cubic_rotation(transforms[previous_idx].basis, angular_w_velocities[previous_idx], transforms[next_idx].basis, angular_w_velocities[next_idx], keyframe_times[next_idx] - keyframe_times[previous_idx], t)
		
	var o1 := transforms[previous_idx].origin
	var o2 := transforms[next_idx].origin
	
	match origin_interp_types[previous_idx]:
		OriginInterpType.LERP:
			trns.origin = transforms[previous_idx].origin.lerp(transforms[next_idx].origin, t)
		OriginInterpType.SLERP:
			trns.origin = transforms[previous_idx].origin.slerp(transforms[next_idx].origin, t)
		OriginInterpType.HERMITE_CUBIC:
			var v1 := origin_velocities[previous_idx]
			var v2 := origin_velocities[next_idx]
			var d := keyframe_times[next_idx] - keyframe_times[previous_idx]
			trns.origin = hermite_cubic_v3(o1, v1, o2, v2, d, t)
		
	
	return trns
