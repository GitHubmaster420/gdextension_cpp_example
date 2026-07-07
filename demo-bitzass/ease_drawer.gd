@tool
extends ColorRect
class_name EaseDrawer

const COLOR := Color("1dd1c9")

const DRAW_COLOR := Color(0.845, 0.071, 0.0, 1.0)

@export var v_slider : VSlider

func _init() -> void:
	color = COLOR

func _ready() -> void:
	if not v_slider:
		return
	v_slider.value_changed.connect(func(v : float):
		ease_amount = v
		)

@export_range(0.0, 1.0, 0.01) var ease_amount := 1.0:
	set(v):
		ease_amount = v
		queue_redraw()

func _draw() -> void:
	var ps : PackedVector2Array
	for i in range(100):
		var x := float(i) / 99.0
		var y := ease_amount * ease(x, ease_amount)
		ps.append(Vector2(x, 1.0 - y) * size)
	draw_polyline(ps, DRAW_COLOR)
