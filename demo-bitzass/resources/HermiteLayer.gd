@tool
class_name HermiteLayer extends Layer

@export var use_hermite_origin := false

func interpolate(t : float) -> Transform3D:
	var info := get_interpolation_info(t)
	var start_frame:= info.x
	var end_frame:= info.y
	var relative_t := info.z
	
	var w1 := previous_layer.get_w_velocity(start_frame / AnimPlayerModifier.FPS)
	var w2 := previous_layer.get_w_velocity(end_frame / AnimPlayerModifier.FPS)

	var t1 := transforms[int(start_frame)]
	var t2 := transforms[int(start_frame)]
	
	var basis := AnimTrack.hermite_cubic_rotation(t1.basis.orthonormalized(), w1, t2.basis.orthonormalized(), w2, (end_frame - start_frame) / AnimPlayerModifier.FPS, relative_t)
	
	var origin : Vector3
	
	if use_hermite_origin:
		var v1 := previous_layer.get_velocity(start_frame / AnimPlayerModifier.FPS)
		var v2 := previous_layer.get_velocity(end_frame / AnimPlayerModifier.FPS)
		
		origin = AnimTrack.hermite_cubic_v3(t1.origin, v1, t2.origin, v2, (end_frame - start_frame) / AnimPlayerModifier.FPS, relative_t)
	else:
		origin = t1.origin.lerp(t2.origin, relative_t)
	
	return Transform3D(basis, origin)
