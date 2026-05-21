@tool
extends MenuOption
class_name AddMenuOption

signal top_down_menu_was_set

@export var top_down_menu : TopDownMenu:
	set(v):
		top_down_menu = v
		if top_down_menu:
			top_down_menu_was_set.emit()

@export var hovered := false:
	set(value):
		hovered = value
		if not top_down_menu:
			await top_down_menu_was_set
		if hovered:
			self_modulate = top_down_menu.hovered_color
		else:
			self_modulate = top_down_menu.unhovered_color

@export var pose_recorder : PoseRecorder

func select(jc : JoyCon):
	pose_recorder.state = PoseRecorder.State.WAITING_TO_START
	pose_recorder.new_action = AnimationRes.new()
