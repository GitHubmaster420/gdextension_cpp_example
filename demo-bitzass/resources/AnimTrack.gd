@tool
extends Resource

class_name AnimTrack 

@export var current_frame : int

## Index for dictionaries is frame

@export var transforms : Dictionary[int, Transform3D]

@export var origin_velocities : Dictionary[int, Vector3] #Optional, used for hermite interpolation

@export var angular_w_velocities : Dictionary[int, Vector3] #Tangent in quaternion space

@export var additional_information : Dictionary[int, Array] # int for safety

@export var layer_times : Dictionary[Layer, PackedInt32Array]

var layer_keys_sorted : Array[Layer]:
	get:
		var keys : Array[Layer]
		keys.assign(layer_times.keys())
		keys.sort_custom(func(a : Layer, b : Layer): return a.index < b.index)
		return keys

func update_auto_layer(noise_threshold : float):
	var layer := lerp_auto_layer
	layer.index = 0
	var tracked_frames : Array[int]
	
	for frame in additional_information:
		for a_i in additional_information[frame]:
			if "tracking_state" in a_i:
				if a_i["tracking_state"] == Kinect.TrackingState.TRACKED:
					tracked_frames.append(frame)
	
	layer_times[layer as Layer] = layer.generate_times(tracked_frames, transforms, noise_threshold)
	var hermite_layer := hermite_auto_layer
	hermite_auto_layer.index = 1
	hermite_layer.previous_layer = layer
	hermite_auto_layer.initiate_transforms_from_previous_layer(layer_times[layer as Layer])
	layer_times[hermite_layer as Layer] = layer_times[layer as Layer]

var lerp_auto_layer : AutoLerpLayer:
	get:
		for layer : Layer in layer_times.keys():
			if layer is AutoLerpLayer:
				return layer
		var layer := AutoLerpLayer.new()
		return layer

var hermite_auto_layer : AutoHermiteLayer:
	get:
		for layer : Layer in layer_times.keys():
			if layer is AutoHermiteLayer:
				return layer
		return AutoHermiteLayer.new()

func initiate_first_layer(first_layer : Layer, times : PackedInt32Array = transforms.keys()):
	layer_times[first_layer] = times

enum BasisInterpType{
	QUAT_SLERP,
	HERMITE_CUBIC
}

@export var basis_interp_types : Dictionary[int, BasisInterpType]

enum OriginInterpType{
	LERP,
	HERMITE_CUBIC,
	SLERP
}

@export var origin_interp_types : Dictionary[int, OriginInterpType]

@export var interp_curves : Dictionary[int, Curve]

func interpolate_layers(t : float) -> Transform3D:
	var current_transforms := transforms.duplicate()
	var layers : Array[Layer] = layer_keys_sorted
	layers[0].transforms = current_transforms
	if layer_times[layers[0]].size() == 0:
		return interpolate_transforms(t)
	for edit_layer_idx in range(1, layer_times.size(), 1):
		var layer := layers[edit_layer_idx]
		if layer_times[layer].size() == 0:
			return interpolate_transforms(t)
		var prev_layer := layers[edit_layer_idx - 1]
		layer.previous_layer = prev_layer
		layer.initiate_transforms_from_previous_layer(layer_times[layer])
	return layers[-1].interpolate(t)

#Probably should remove and use gt_early_idx
func find_closest_frame(frame : int, d : Dictionary) -> int:
	if d.size() == 0:
		push_error()
	var sorted : Array[int]
	sorted.assign(d.keys().duplicate()) #Duplicating to be safe
	sorted.sort()
	var best_match := sorted[0]
	for i in range(1, sorted.size()):
		if sorted[i] < frame:
			best_match = sorted[i]
		else:
			if sorted[i] - frame > frame - best_match:
				best_match = sorted[i]
			break
	return best_match


func add_keyframe(keyframe : KeyFrame):
	var frame := keyframe.frame
	transforms[frame] = keyframe.transform
	if keyframe.velocity != Vector3.INF:
		origin_velocities[frame] = keyframe.velocity
	if transforms.size() == 1:
		return
	basis_interp_types[frame] = keyframe.basis_type
	origin_interp_types[frame] = keyframe.origin_type
	if keyframe.curve:
		interp_curves[frame] = keyframe.curve

func slerp_quats(b1 : Basis, b2 : Basis, t) -> Basis:
	return Quaternion(b1.orthonormalized()).slerp(b2.orthonormalized(), t)

func squad(qs : Quaternion, qe : Quaternion, ts : Quaternion, te : Quaternion, t : float):
	var s1 := qs.slerp(qe, t)
	var s2 := ts.slerp(te, t)
	return s1.slerp(s2, 2.0 * t * (1.0 - t))

static func angular_velocity(quats: Array[Quaternion], dt: float) -> Vector3:
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

static func quat_log(q: Quaternion) -> Vector3:
	var v = Vector3(q.x, q.y, q.z)
	var v_len = v.length()
	if v_len < 1e-8:
		return Vector3.ZERO
	var angle = atan2(v_len, q.w)
	return v.normalized() * angle

static func quat_exp(v: Vector3) -> Quaternion:
	var angle := v.length()
	if angle < 1e-8:
		return Quaternion(0, 0, 0, 1)

	var axis := v / angle
	var s := sin(angle)
	return Quaternion(axis.x * s, axis.y * s, axis.z * s, cos(angle))

static func hermite_cubic_rotation(q1: Quaternion, w1: Vector3, q2: Quaternion, w2: Vector3, dt: float, t: float) -> Quaternion:
	# Compute tangent quaternions from angular velocities
	# The factor 0.5 comes from quaternion log conventions
	var a := q1 * quat_exp(-0.25 * w1 * dt)
	var b := q2 * quat_exp(0.25 * w2 * dt)
	
	# SQUAD-style blending
	var s1 := q1.slerp(q2, t)
	var s2 := a.slerp(b, t)
	return s1.slerp(s2, 2.0 * t * (1.0 - t)).normalized()

static func hermite_cubic_v3(o1 : Vector3, v1 : Vector3, o2 : Vector3, v2 : Vector3, d : float, t) -> Vector3:
	var cp_1 := o1 + v1 / 3.0 * d #Velocities have to be divided by 3 according to chatgpt
	var cp_2 := o2 - v2 / 2.0 * d
	return o1.bezier_interpolate(cp_1, cp_2, o2, t)

func get_early_idx(d : Dictionary, frame : int) -> Vector2i:
	if d.size() < 2:
		return Vector2i(d.keys()[0], d.keys()[0])
	var indices : Array[int]
	indices.assign(d.keys().duplicate())
	indices.sort()
	var early_idx := indices[-1]
	var j := 0
	for i in range(1, indices.size()):
		if indices[i] > frame:
			j = i
			early_idx = indices[i - 1]
			break
	var late_idx := indices[j]
	return Vector2i(early_idx, late_idx)

func interpolate_transforms(time : float) -> Transform3D:
	var frame := floori(time * AnimPlayerModifier.FPS)
	if transforms.size() == 0:
		return Transform3D()
	if transforms.size() == 1:
		return transforms[transforms.keys()[0]]
	var idx_v := get_early_idx(transforms, frame)
	var early_idx := idx_v.x
	var late_idx := idx_v.y
	
	var t := 0.0
	if late_idx != early_idx:
		t = (float(frame - early_idx) / float(late_idx - early_idx))
	#for i in range(keyframe_times.size()):
		#if time > keyframe_times[i]:
			#next_idx = i + 1
			#previous_idx = next_idx - 1
			#t = (time - keyframe_times[previous_idx]) / (keyframe_times[next_idx] - keyframe_times[previous_idx])
			#break
	t = clampf(t, 0, 1)
	if interp_curves.size() > 0:
		var previous_idx := get_early_idx(interp_curves, frame).y
		t = interp_curves[previous_idx].sample(t)
	#print("t: ", t)
	var trns := Transform3D()
	
	var basis_idx := get_early_idx(basis_interp_types, frame).y
	
	match basis_interp_types[basis_idx]:
		BasisInterpType.QUAT_SLERP:
			trns.basis = slerp_quats(transforms[early_idx].basis, transforms[late_idx].basis, t)
		BasisInterpType.HERMITE_CUBIC:
			var start_w := Vector3.ZERO
			var end_w := Vector3.ZERO
			if angular_w_velocities.size() != 0:
				
				var angular_w_start_idx = find_closest_frame(early_idx, angular_w_velocities)
				var angular_w_end_idx := find_closest_frame(late_idx, angular_w_velocities)
				start_w = angular_w_velocities[angular_w_start_idx]
				end_w = angular_w_velocities[angular_w_end_idx]
			trns.basis = Basis(hermite_cubic_rotation(Quaternion(transforms[early_idx].basis.orthonormalized()), start_w, Quaternion(transforms[late_idx].basis.orthonormalized()), end_w, float(late_idx - early_idx) / AnimPlayerModifier.FPS, t))
	var o1 := transforms[early_idx].origin
	var o2 := transforms[late_idx].origin
	
	var origin_idx := get_early_idx(origin_interp_types, frame).y
	
	match origin_interp_types[origin_idx]:
		OriginInterpType.LERP:
			trns.origin = o1.lerp(o2, t)
		OriginInterpType.SLERP:
			trns.origin = o1.slerp(o2, t)
		OriginInterpType.HERMITE_CUBIC:
			var start_v := Vector3.ZERO
			var end_v := Vector3.ZERO
			if origin_velocities.size() > 0:
				var velocity_start_idx = find_closest_frame(early_idx, origin_velocities)
				var velocity_end_idx := find_closest_frame(late_idx, origin_velocities)
				start_v = origin_velocities[velocity_start_idx]
				end_v = origin_velocities[velocity_end_idx]
			var d := float(late_idx - early_idx) / AnimPlayerModifier.FPS
			var v1 := start_v
			var v2 := end_v
			trns.origin = hermite_cubic_v3(o1, v1, o2, v2, d, t)
		
	
	return trns

func get_additional_info(frame : int) -> Array:
	if additional_information.size() == 0:
		return[]
	var current_frames : Array[Dictionary]
	
	for i in additional_information:
		for d : Dictionary in additional_information[i]:
			if frame >= i:
				current_frames.append(d)
				break
	return current_frames
	
