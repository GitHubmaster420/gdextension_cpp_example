@tool
extends Control
class_name TopDownMenu

@export var unhovered_color = Color(0.58, 0.58, 0.58, 1.0)
@export var hovered_color = Color(0.406, 0.367, 0.94, 1.0)

@export_tool_button("add option") var a_o = add_option
@export_tool_button("remove option") var r_o = remove_top_option

@export var stick_input := Vector2.ZERO:
	set(v):
		var was_zero := absf(stick_input.y) < 0.5
		stick_input = v
		if was_zero:
			if stick_input.y > 0.5:
				selected_option -= 1
			elif stick_input.y < -0.5:
				selected_option += 1
		

@export var world : World

@export var pose_recorder : PoseRecorder

var active := false:
	set(value):
		if active == value:
			return
		visible = value
		if not value and world.active_menu == self:
			world.active_menu = null
		if value:
			world.active_menu = self
		await get_tree().process_frame
		active = value
			
		

func remove_top_option():
	remove_option(get_child_count() - 1)

var option_size : Vector2:
	get:
		return (get_child(0) as ColorRect).size

@export var amount_of_options := 1:
	set(v):
		amount_of_options = clamp(v, 1, get_child_count())
		for c : ColorRect in get_children():
			c.size = option_size
			c.position = Vector2.ZERO
			c.position.y += option_size.y * c.get_index()

@export var selected_option := 0:
	set(v):
		if selected_option > -1:
			if selected_option > -1 and selected_option < get_child_count():
				get_child(selected_option).hovered = false
				
		selected_option = clampi(v, 0, get_child_count() - 1)
		if selected_option != -1:
			get_child(selected_option).hovered = true
	get:
		return clampi(selected_option, 0, get_child_count() - 1)
		

func add_option(anim : AnimationRes):
	var option := ExistingActionOption.new(get_child_count(), option_size)
	option.name = str(get_child_count())
	add_child(option)
	if Engine.is_editor_hint():
		option.owner = owner
		for c in option.get_children():
			c.owner = owner
	amount_of_options += 1
	option.top_down_menu = self
	option.hovered = false
	option.pose_recorder = pose_recorder

func select_current(jc : JoyCon):
	(get_child(selected_option) as MenuOption).select(jc)
	active = false

func remove_option(option_idx : int):
	if option_idx == 0:
		return
	selected_option = -1
	amount_of_options -= 1
	get_child(option_idx).queue_free()
