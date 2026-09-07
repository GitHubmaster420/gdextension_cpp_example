@tool
class_name MyEaseInOut
extends Resource

@export_range(-1.0, 1.0, 0.01) var start_influence := 0.2:
	set(v):
		start_influence = v
		weight_1 = pow(10, start_influence)
		set_points()
		bake_fast()
		changed.emit()
		

var weight_1 : float

@export_range(-1.0, 1.0, 0.01) var end_influence := 0.2:
	set(v):
		end_influence = v
		weight_2 = pow(10, end_influence)
		
		set_points()
		bake_fast()
		changed.emit()
		

var weight_2 : float

@export_range(0.0, 1.0, 0.01) var mid_point := 0.5:
	set(v):
		mid_point = v
		set_points()
		bake_fast()
		changed.emit()

@export var points : PackedVector2Array

@export var baked_points : PackedFloat32Array

static func rational_cubic_bezier(
		p0: Vector2, p1: Vector2,
		p2: Vector2, p3: Vector2,
		w0: float, w1: float,
		w2: float, w3: float,
		t: float) -> Vector2:

	var omt := 1.0 - t

	var b0 := omt * omt * omt
	var b1 := 3.0 * omt * omt * t
	var b2 := 3.0 * omt * t * t
	var b3 := t * t * t

	var numerator := (
		p0 * (w0 * b0) +
		p1 * (w1 * b1) +
		p2 * (w2 * b2) +
		p3 * (w3 * b3)
	)

	var denominator := (
		w0 * b0 +
		w1 * b1 +
		w2 * b2 +
		w3 * b3
	)

	return numerator / denominator

func set_points(amount : int = 100):
	points.clear()
	for i in range(amount):
		points.append(interpolate(float(i) / float(amount)))

func interpolate(t : float) -> Vector2:
	var p0 := Vector2.ZERO
	var p1 := Vector2(mid_point, 0)
	var p2 := Vector2(mid_point, 1)
	var p3 := Vector2.ONE
	var w0 := 1
	var w1 := weight_1
	var w2 := weight_2
	var w3 := 1
	return rational_cubic_bezier(p0, p1, p2, p3, w0, w1, w2, w3, t)

func bake_fast(point_amount := 4096):
	set_points(point_amount)
	
	var ps : PackedFloat32Array
	
	var p_idx := 0
	for i in range(128):
		var target_x := float(i) / 128.0
		while !(points[p_idx].x >= float(i) / 128.0) and p_idx < points.size() - 1:
			p_idx += 1
		var a := points[p_idx - 1]
		var b := points[p_idx]

		var alpha := inverse_lerp(a.x, b.x, target_x)
		ps.append(lerpf(a.y, b.y, alpha))
	baked_points = ps
		
