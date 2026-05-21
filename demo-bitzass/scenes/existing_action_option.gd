@tool
extends MenuOption
class_name ExistingActionOption

var action_name : String
var anim_player : AnimPlayerModifier

@export var top_down_menu : TopDownMenu

@export var hovered := false:
	set(v):
		hovered = v
		if hovered:
			self_modulate = top_down_menu.hovered_color
		else:
			self_modulate = top_down_menu.unhovered_color

var pose_recorder : PoseRecorder:
	set(v):
		pose_recorder = v
		anim_player = pose_recorder.anim_player
		action_name = anim_player.current_animation_name

func _init(i := 1, _size = size) -> void:
	pivot_offset_ratio = Vector2(0.5, 0.5)
	var label := Label.new()
	add_child(label)
	label.text = str(i)
	label.add_theme_color_override("font_color", Color.GREEN)
	label.pivot_offset = Vector2(0.5, 0.5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	size = _size
	label.size = Vector2(80, 80)
	label.position = size / 2.0 - label.size / 2.0
	label.add_theme_font_size_override("font_size", 40)
	
func select(jc : JoyCon):
	pose_recorder.state = PoseRecorder.State.POST_PROCESSING
	anim_player.current_animation_name = action_name
