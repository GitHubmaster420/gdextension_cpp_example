extends ColorRect
class_name PieMenu

var stick_input := Vector2.ZERO

@export var world : World

var control_jc : JoyCon

signal active_set(value)

var active := false:
	set(v):
		active = v
		active_set.emit(active)
		world.active_menu = self if active else (null if world.active_menu == self else world.active_menu)
		visible = active
		process_mode = Node.PROCESS_MODE_ALWAYS if active else Node.PROCESS_MODE_DISABLED
		if not active:
			control_jc = null
			

var shader_material : ShaderMaterial:
	get:
		return (material as ShaderMaterial)

var selected_chunk := -1:
	set(value):
		selected_chunk = value
		shader_material.set_shader_parameter("selected_chunk", selected_chunk)

var chunk_count : int:
	get:
		return get_child_count()

func on_y_pressed(jc : JoyCon):
	print("y pressed on pie menu")
	control_jc = jc
	active = true

func _ready() -> void:
	active = false
	shader_material.set_shader_parameter("chunks", chunk_count)

func _process(_delta: float) -> void:
	if stick_input.length_squared() < 0.25:
		selected_chunk = -1
	else:
		var angle := atan2(-stick_input.y, -stick_input.x)
		var angle_divisor := PI * 2.0 / float(chunk_count)
		var angle_pos := angle + PI
		selected_chunk = int(angle_pos / angle_divisor + 0.5) % chunk_count
	

func on_b_pressed(joycon : JoyCon):
	if joycon == control_jc:
		active = false

func on_a_pressed(joycon : JoyCon):
	return
	if joycon == control_jc:
		select_chunk()

func on_zr_pressed(joycon : JoyCon):
	if joycon != control_jc: return
	select_chunk()


func select_chunk():
	var jc := control_jc
	active = false
	(get_child(selected_chunk) as MenuOption).select(jc)
	
