extends StickOption

@export var bone_constraints : Array[SkeletonModifier3D]

#TODO: bloom
const turned_on_color := Color(0.0, 1.0, 0.0, 1.0)
const turned_off_color := Color(0.988, 0.0, 0.0, 1.0)
const active_color := Color.WHITE
const inactive_color := Color(0.337, 0.337, 0.722, 1.0)


@export var additional_options : PieMenu:
	set(v):
		additional_options = v
		if not additional_options:
			return
		if not stick_ui:
			await stick_ui_set
		additional_options.active_set.connect(func(a : bool):
			if a:
				stick_ui.active = false
				stick_ui.world.previous_menus.append(stick_ui)
			)
				
var icon : CanvasItem

signal stick_ui_set

var stick_ui : StickUI:
	set(v):
		stick_ui = v
		if stick_ui:
			stick_ui_set.emit()
		

func _ready() -> void:
	turn_on()
	deactivate()
	deselect()
	if additional_options:
		additional_options.global_position = get_global_transform().origin + -additional_options.size / 2.0
		var m_e := MeshInstance2D.new()
		var m := SphereMesh.new()
		m.radius = 10
		m.height = 20
		m_e.mesh = m
		m_e.self_modulate = Color(1.0, 0.0, 0.017, 1.0)
		m_e.top_level = true
		add_child(m_e)
		m_e.global_position = get_global_transform().origin
		m_e.z_index = 10
		icon = m_e
		additional_options.active_set.connect(func(a : bool): icon.visible = not a)

func on_zr_pressed():
	select()

func on_y_pressed(jc : JoyCon):
	print("y pressed")
	if additional_options:
		additional_options.on_y_pressed(jc)
		icon.visible = true

func select():
	modulate.a = 1.0

func deselect():
	modulate.a = 0.25

func activate():
	var a := modulate.a
	modulate = Color(active_color)
	modulate.a = a

func deactivate():
	var a := modulate.a
	modulate = Color(inactive_color)
	modulate.a = a

func turn_on():
	for b in bone_constraints:
		b.active = true
	self_modulate = turned_on_color

func turn_off():
	for b in bone_constraints:
		b.active = false
	self_modulate = turned_off_color
	
