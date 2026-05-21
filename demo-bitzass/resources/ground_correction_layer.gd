@tool
extends Layer
class_name GroundCorrectionLayer

@export var ground_heights : Dictionary[int, float]:
	set(v):
		ground_heights = v





func interpolate(t : float) -> Transform3D:
	var frame : int = t * AnimPlayerModifier.FPS
	
	var baked_keys : Array[int]
	baked_keys.assign(ground_heights.keys())
	baked_keys.sort()
	
	var first_frame : int = baked_keys[0]
	var last_frame : int = baked_keys[-1]
	
	for i in ground_heights.keys():
		if i > frame:
			last_frame = i
			break
		first_frame = i
	var _t := clampf(float(frame - first_frame) / float(last_frame - first_frame), 0, 1)
	if first_frame == last_frame:
		_t = 1
	var h := lerpf(ground_heights[first_frame], ground_heights[last_frame], _t)
	var info := get_interpolation_info(t)

	
	var t1 := transforms[int(info.x)]
	var t2 := transforms[int(info.y)]
	
	var relative_t := info.z
	
	var trns : Transform3D
	
	trns.basis = t1.basis.orthonormalized().slerp(t2.basis.orthonormalized(), relative_t)
	trns.origin = t1.origin.lerp(t2.origin, relative_t)
	
	trns.origin.y -= h
	
	return trns
