extends Node3D
class_name World

@export var main_menu : PieMenu

@export var joycon_pie : PieMenu

var joycons : Array[JoyCon]

var active_joycon : JoyCon

var active_menu : CanvasItem:
	set(v):
		if v == null and previous_menus.size() != 0:
			active_menu = previous_menus.pop_back()
			#Hacky way to make visible without setting active
			active_menu.visible = true
			return
		active_menu = v

var previous_menus : Array[CanvasItem]

@export var kinect : Kinect

@export var camera_parent : Node3D

func joycon_pressed_y(joycon : JoyCon):
	if active_menu:
		DuckTyper.call_func_duck_typed(active_menu, "on_y_pressed", joycon)
	else:
		main_menu.on_y_pressed(joycon)
		active_joycon = joycon

func joycon_pressed_b(joycon : JoyCon):
	if not active_menu:
		return
	DuckTyper.call_func_duck_typed(active_menu, "on_b_pressed", joycon)

func joycon_pressed_a(joycon : JoyCon):
	if not active_menu:
		active_joycon = joycon
		return
	DuckTyper.call_func_duck_typed(active_menu, "on_a_pressed", joycon)
	# TODO: More generic menu system

func joycon_pressed_zr(joycon : JoyCon):
	if not active_menu:
		return
	DuckTyper.call_func_duck_typed(active_menu, "on_zr_pressed", joycon)

func joycon_pressed_x(joycon : JoyCon):
	if not active_menu:
		return
	DuckTyper.call_func_duck_typed(active_menu, "on_x_pressed", joycon)

func _ready() -> void:
	camera_parent.rotation_order = EULER_ORDER_YXZ

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if active_joycon:
		if active_menu:
			DuckTyper.set_variable_duck_typed(active_menu, "stick_input", active_joycon.input_dir)
		else:
			var dir := active_joycon.input_dir
			if dir.length_squared() > 0.25:
				camera_parent.rotate_y(dir.x * delta * 2.0)
				camera_parent.rotate_object_local(Vector3.RIGHT, -dir.y * delta)
				
				camera_parent.rotation.x = clampf(camera_parent.rotation.x,-PI/8.0, PI/8.0)
				
			# Move camera here


func add_joycon(joycon : JoyCon):
	joycon.y_just_pressed.connect(joycon_pressed_y.bind(joycon))
	joycon.b_just_pressed.connect(joycon_pressed_b.bind(joycon))
	joycon.a_just_pressed.connect(joycon_pressed_a.bind(joycon))
	joycon.zr_just_pressed.connect(joycon_pressed_zr.bind(joycon))
	joycon.x_just_pressed.connect(joycon_pressed_x.bind(joycon))
	
