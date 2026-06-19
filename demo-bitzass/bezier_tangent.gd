extends ColorRect
class_name BezierTangent

var selected := false:
	set(v):
		selected = v
		if not is_node_ready():
			return
		if not selected:
			delta_angle = 0
			last_mouse_pos = Vector2.INF

var delta_angle : float = 0

var last_mouse_pos : Vector2

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			selected = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			selected = false
