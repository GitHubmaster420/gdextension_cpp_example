@tool
class_name LerpLayer extends Layer

@export var curves : Dictionary[int, MyCurve]

func interpolate(t : float) -> Transform3D:
	var info := get_interpolation_info(t)
	
	var t1 := transforms[int(info.x)]
	var t2 := transforms[int(info.y)]
	
	var relative_t := info.z
	
	if int(info.y) in curves:
		relative_t = curves[int(info.y)].interpolate_baked(relative_t)
	
	var trns : Transform3D
	
	trns.basis = t1.basis.orthonormalized().slerp(t2.basis.orthonormalized(), relative_t)
	trns.origin = t1.origin.lerp(t2.origin, relative_t)
	
	return trns
