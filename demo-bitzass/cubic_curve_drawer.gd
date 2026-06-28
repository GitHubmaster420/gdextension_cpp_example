@tool
extends ColorRect
class_name EaseCurveDrawer

func _init() -> void:
	color = Color("003508")

@export var my_ease_in_out_curve : MyEaseInOut:
	set(v):
		if my_ease_in_out_curve:
			my_ease_in_out_curve.changed.disconnect(queue_redraw)
		my_ease_in_out_curve = v
		if not my_ease_in_out_curve:
			return
		my_ease_in_out_curve.changed.connect(queue_redraw)
		my_ease_in_out_curve.start_influence = my_ease_in_out_curve.start_influence
		my_ease_in_out_curve.end_influence = my_ease_in_out_curve.end_influence
		my_ease_in_out_curve.mid_point = my_ease_in_out_curve.mid_point

#ease: 1−(1−x)^curve

func _draw() -> void:
	if not my_ease_in_out_curve:
		return
	var points : PackedVector2Array
	var arr := my_ease_in_out_curve.baked_points
	for i in range(arr.size()):
		points.append(Vector2(float(i) / (arr.size()-1), arr[i]) * size * (Vector2.UP + Vector2.RIGHT) - Vector2.UP * size.y)
	draw_polyline(points, Color.MAGENTA)
