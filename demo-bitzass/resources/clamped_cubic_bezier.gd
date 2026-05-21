@tool
extends MyCurve
class_name ClampedCubicBezier

@export_range(-PI/4.0, PI / 4.0) var start_angle := 0.0:
	set(v):
		start_angle = v
		bake_if_possible(get_required_args())
@export_range(-PI/4.0, PI / 4.0) var end_angle := 0.0:
	set(v):
		end_angle = v
		bake_if_possible(get_required_args())

func get_required_args() -> Array:
	return [start_angle, end_angle]

func interpolate_normalized(t : float) -> Vector2:
	var distance := 0.5
	var p1 := Vector2.ZERO + Vector2(sin(start_angle + PI/4.0), cos(start_angle + PI/4.0)) * distance
	var p2 := Vector2.ONE - Vector2(sin(end_angle + PI/4.0), cos(end_angle + PI/4.0)) * distance
	return Vector2.ZERO.bezier_interpolate(p1, p2, Vector2.ONE, t)
