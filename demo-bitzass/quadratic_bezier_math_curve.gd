@tool
extends Node2D
class_name QuadraticBezierMathCurve

@export var middle: Marker2D
@export var line_2d: Line2D

@export var size := Vector2(100, 100):
	set(v):
		size = v


@export_range(-1.0, 1.0, 0.01) var offset := 0.0:
	set(v):
		offset = clampf(v, -1.0, 1.0)
		if not size:
			await ready
		var left_top = Vector2(0, -size.y)
		var right_bottom = Vector2(size.x, 0)
		if not middle:
			await ready
		middle.position = left_top.lerp(right_bottom, (offset+1) / 2.0)
		update_line()

@export var point_count := 100:
	set(v):
		point_count = v
		update_line()

@export var points : Array[float]

func interpolate_line(t : float):
	var l1 := Vector2.ZERO.lerp(middle.position, t)
	var l2 := middle.position.lerp(Vector2(size.x, -size.y), t)
	return l1.lerp(l2, t)

func interpolate_normalized(t : float) -> Vector2:
	var left_top = Vector2(0, 1.0)
	var right_bottom = Vector2(1.0, 0)
	var mid_pos := left_top.lerp(right_bottom, (offset+1) / 2.0)
	var l1 := Vector2.ZERO.lerp(mid_pos, t)
	var l2 := mid_pos.lerp(Vector2.ONE, t)
	return l1.lerp(l2, t)

func update_line():
	var _points : PackedVector2Array
	for i in point_count + 1:
		var t := float(i) / float(point_count)
		_points.append(interpolate_line(t))
	line_2d.points = _points

@export_tool_button("bake") var b := bake

func bake(resolution := 100):
	var _points : Array[float]
	var original : Array[Vector2]
	for i in range(resolution):
		original.append(interpolate_normalized(float(i) / float(resolution)))
	var current_x := 0
	var prev_point := Vector2.ZERO
	for point in original:
		var point_x := int(point.x * float(resolution))
		if point_x > current_x:
			var amount := point_x - current_x
			for i in range(amount):
				_points.append(lerpf(prev_point.y, point.y, float(i) / amount))
			prev_point = point
			current_x = point_x
	_points.append(1.0)
	points = _points

@export_tool_button("visualize baked") var vb = visualize_baked

func visualize_baked():
	var _points : PackedVector2Array
	for i in range(points.size()):
		var t := float(i) / float(points.size())
		var x := t * size.x
		var y := -(points[i] * size.y)
		_points.append(Vector2(x, y))
	line_2d.points = _points

func interpolate_baked(t : float) -> float:
	t = clampf(t, 0.0, 1.0)
	return points[int(t * float(points.size() - 1))]
	
