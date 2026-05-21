extends Control
class_name PostProcessor

@export var world : World

@export var anim_player : AnimPlayerModifier

@export var stick_input : Vector2:
	set(value):
		if not anim_player:
			await ready
		stick_input = value
		anim_player.current_time += stick_input.x / anim_player.FPS * 0.5

@export var pose_recorder : PoseRecorder

var active := false:
	set(value):
		active = value
		if not world:
			await ready
		if active:
			world.active_menu = self
		elif world.active_menu == self:
			world.active_menu = null

func on_zr_pressed(jc : JoyCon):
	pose_recorder.state += 1
	active = false
		
