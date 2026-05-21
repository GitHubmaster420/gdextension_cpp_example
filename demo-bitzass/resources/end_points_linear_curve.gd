@tool
extends MyCurve
class_name EndPointsLinearCurve

@export_range(-PI/4.0, PI/4.0, 0.01) var angle := 0.0:
	
	set(v):
		angle = v
		bake_if_possible(get_required_args())

@export_range(-0.5, 0.5) var offset := 0.0:
	set(v):
		offset = v
		bake_if_possible(get_required_args())

@export var mid_point := Vector2.INF:
	set(v):
		if v == Vector2.INF:
			mid_point = Vector2.INF
			bake_if_possible(get_required_args())
			return
		mid_point = v.clamp(Vector2.ZERO, Vector2.ONE)
		bake_if_possible(get_required_args())

@export_tool_button("set current to mid") var sctmd = set_mid_point_to_current 

func set_mid_point_to_current():
	var stored_angle := get_derivative_baked(current_t)
	mid_point = Vector2(current_t, interpolate_baked(current_t))
	angle = stored_angle

func get_required_args() -> Array:
	return [angle, point_count, offset]

func get_derivative_baked(t : float) -> float:
	t = clampf(t, 0.0, 1.0)
	var first_idx := int(t * float(points.size() - 1))
	var first := points[first_idx] if first_idx < points.size() - 1 else points[first_idx - 1]
	var next := points[first_idx + 1] if first_idx < points.size() - 1 else points[first_idx]
	var diff := 1.0 / float(points.size())
	return atan2(next - first, diff) - PI/4.0

func interpolate_normalized(t : float) -> Vector2:
	
	
	var center_point := Vector2(1.0, 0.0).lerp(Vector2(0.0, 1.0), (offset + 1) / 2.0) if mid_point == Vector2.INF else mid_point
	
	var center_point_t := center_point.dot(Vector2.ONE) / 2.0 #divide both by sqrt of 2
	
	
	var start_pivot_length := center_point_t / 2.0
	
	var end_pivot_legth := (1.0 - center_point_t) / 2.0
	
	var p1 := Vector2(start_pivot_length, start_pivot_length)
	
	var plast := Vector2(1.0 - end_pivot_legth, 1.0 - end_pivot_legth)
	
	var c1 := center_point - Vector2(cos(angle + PI/4.0), sin(angle + PI/4.0)) * start_pivot_length
	var clast := center_point + Vector2(cos(angle + PI/4.0), sin(angle + PI/4.0)) * end_pivot_legth
	
	var result : Vector2
	
	if t < 0.5:
		result = Vector2.ZERO.bezier_interpolate(p1, c1, center_point, t * 2.0)
	else:
		result = center_point.bezier_interpolate(clast, plast, Vector2.ONE, t * 2.0 - 1)
	return result
	
