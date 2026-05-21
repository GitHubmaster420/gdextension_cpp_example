extends ColorRect
class_name EmptyCanvas

signal left_clicked(is_clicked : bool)
signal right_clicked(is_clicked : bool)

func _ready() -> void:
	z_index = -100
	mouse_filter = Control.MOUSE_FILTER_PASS

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			left_clicked.emit(event.pressed)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			right_clicked.emit(event.pressed)
