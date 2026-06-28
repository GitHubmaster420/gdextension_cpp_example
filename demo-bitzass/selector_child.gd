extends ColorRect
class_name SelectorChild

signal clicked(object)

signal shift_clicked(object)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if event.shift_pressed:
				shift_clicked.emit(self)
				print("emitting shift clicked")
			else:
				clicked.emit(self)
