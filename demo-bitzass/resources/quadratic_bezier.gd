@tool
extends MyCurve
class_name QuadraticBezierCurve

@export_range(-1.0, 1.0, 0.01) var offset := 0.0:
	set(v):
		if offset == v:
			return
		offset = clampf(v, -1.0, 1.0)
		bake_if_possible(get_required_args())

func get_required_args() -> Array:
	return [offset, point_count]

func _init() -> void:
	offset = 0.0
	point_count = 100
	bake()

func interpolate_normalized(t : float) -> Vector2:
	var left_top = Vector2(0, 1.0)
	var right_bottom = Vector2(1.0, 0)
	var mid_pos := left_top.lerp(right_bottom, (offset+1) / 2.0)
	var l1 := Vector2.ZERO.lerp(mid_pos, t)
	var l2 := mid_pos.lerp(Vector2.ONE, t)
	return l1.lerp(l2, t)

@export_tool_button("bake") var b := bake



	
