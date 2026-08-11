extends TextureButton
class_name BallSelector

@export var ball_key_frames : BallKeyFrames

func _ready() -> void:
	toggled.connect(func(b : bool):
		ball_key_frames.active = b
	)

func _input(event: InputEvent) -> void:
	pass
