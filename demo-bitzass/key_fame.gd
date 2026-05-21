extends ColorRect
class_name Keyframe

var hovered := false

@export var animator : Animator

@export var time : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation = deg_to_rad(45)
	size = Vector2.ONE * 10

signal clicked(was_clicked : bool)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(event.pressed and hovered)
