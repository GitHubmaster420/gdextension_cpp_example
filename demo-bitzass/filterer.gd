extends Control
class_name Filterer

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_H and event.pressed:
			visible = not visible
