extends ColorRect
class_name Lasso

@export var timeline : MasterTime

var left_pos : float
var right_pos : float

var start_pos : float

signal lassoed

func _ready() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if not event.pressed:
				if visible:
					lassoed.emit()
				visible = false
				return
			if event.shift_pressed and is_inside_timeline():
				start_lasso()

func is_inside_timeline():
	var mouse_pos := get_global_mouse_position()
	var left_top := timeline.global_position
	var right_bottom := left_top + timeline.size
	return mouse_pos.x > left_top.x and mouse_pos.x < right_bottom.x and mouse_pos.y > left_top.y and mouse_pos.y < right_bottom.y

func start_lasso():
	visible = true
	var m := get_global_mouse_position().x
	start_pos = m
	left_pos = m
	right_pos = m

func _process(delta: float) -> void:
	if not visible:
		return
	var m := get_global_mouse_position().x
	if m > start_pos:
		
		right_pos = m
		left_pos = start_pos
	else:
		left_pos = m
		right_pos = start_pos
	global_position.x = left_pos
	size.x = absf(right_pos - left_pos)
