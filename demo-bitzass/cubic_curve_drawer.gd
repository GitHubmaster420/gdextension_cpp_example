@tool
class_name CubicCurveDrawer
extends ColorRect

@export var sliders : Array[VSlider]

func _ready() -> void:
	if sliders.size() >= 4:
		sliders[0].value_changed.connect(func(v : float):
			if not nested_cubic:
				return
			nested_cubic.a = v)
		sliders[1].value_changed.connect(func(v : float):
			if not nested_cubic:
				return
			nested_cubic.b = v)
		sliders[2].value_changed.connect(func(v : float):
			if not nested_cubic:
				return
			nested_cubic.c = v)
		sliders[3].value_changed.connect(func(v : float):
			if not nested_cubic:
				return
			nested_cubic.d = v)
		

@export var nested_cubic : NestedCubicCurve:
	set(v):
		if nested_cubic:
			nested_cubic.changed.disconnect(queue_redraw)
		nested_cubic = v
		queue_redraw()
		if not nested_cubic:
			return
		if sliders.size() >= 4:
			sliders[0].value = nested_cubic.a
			sliders[1].value = nested_cubic.b
			sliders[2].value = nested_cubic.c
			sliders[3].value = nested_cubic.d
		
		nested_cubic.changed.connect(queue_redraw)

func _draw() -> void:
	if not nested_cubic:
		return
	var points : PackedVector2Array
	for i in range(100):
		var t := float(i / 100.0)
		points.append(Vector2(t, -nested_cubic.interpolate(t)) * size - Vector2.UP * size.y)
	draw_polyline(points, Color.MAGENTA)
