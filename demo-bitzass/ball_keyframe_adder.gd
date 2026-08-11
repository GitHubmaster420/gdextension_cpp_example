extends TextureRect

@export var master_time : MasterTime

@export var color_rect: MeshInstance2D
@export var color_rect_2: MeshInstance2D
@export var ball_key_frames: BallKeyFrames

const un_hovered_color := Color(0.945, 0.536, 0.0, 1.0)
const hovered_color := Color(0.0, 0.0, 1.0, 1.0)

func _ready() -> void:
	mouse_entered.connect(func():
		color_rect.modulate = hovered_color
		color_rect_2.modulate = hovered_color
		)
	mouse_exited.connect(func():
		color_rect.modulate = un_hovered_color
		color_rect_2.modulate = un_hovered_color
		)
	gui_input.connect(func(event : InputEvent):
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				ball_key_frames.add_key(master_time.time)
		)
