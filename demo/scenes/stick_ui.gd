@tool
extends Control
class_name StickUI

@export var world : World

var active := false:
	set(v):
		active = v
		visible = active
		if active:
			world.active_menu = self
			up_layer.select()
			down_layer.select()
		elif world.active_menu == self:
			world.active_menu = null

@export var stick_layer: GDScript
@export var bone_option: GDScript

@export_tool_button("populate_children") var po = populate_all_children

var active_layer : StickLayer = null:
	set(value):
		if active_layer:
			active_layer.deactivate()
		active_layer = value
		if not active_layer:
			return
		active_layer.activate()

var selected_layer : StickLayer = null:
	set(value):
		up_layer.deselect()
		down_layer.deselect()
		selected_layer = value
		if not selected_layer:
			return
		selected_layer.select()

var stick_input : Vector2:
	set(v):
		stick_input = v
		handle_input(stick_input)

@export var down_layer : StickLayer
@export var up_layer : StickLayer

var active_jc : JoyCon

func select(jc : JoyCon):
	visible = true
	active = true
	active_jc = jc

func _ready() -> void:
	visible = false
	up_layer.stick_ui = self
	down_layer.stick_ui = self

func on_zr_pressed(jc : JoyCon):
	if jc != active_jc:
		return
	if not selected_layer:
		selected_layer = active_layer
	else:
		selected_layer.on_zr_pressed()

func on_b_pressed(jc : JoyCon):
	if jc != active_jc:
		return
	if not selected_layer:
		active = false
		return
	if not selected_layer.selected_sub_layer:
		selected_layer = null
		up_layer.select()
		down_layer.select()
	else:
		selected_layer.on_b_pressed()

func on_a_pressed(jc : JoyCon):
	if jc != active_jc:
		return
	if not selected_layer:
		up_layer.turn_on()
		down_layer.turn_on()
		return
	selected_layer.turn_on()

func on_x_pressed(jc : JoyCon):
	if jc != active_jc:
		return
	if not selected_layer:
		up_layer.turn_off()
		down_layer.turn_off()
		return
	selected_layer.turn_off()

func on_y_pressed(jc : JoyCon):
	if jc != active_jc:
		return
	if selected_layer:
		selected_layer.on_y_pressed(jc)

func populate_all_children():
	populate_children(self)

func populate_children(p : Node):
	for c in p.get_children():
		if c is not MeshInstance2D:
			c.set_script(stick_layer)
		else:
			c.set_script(bone_option)
		populate_children(c)

func handle_input(input_dir : Vector2):
	if not selected_layer:
		if input_dir.length_squared() > 0.25:
			if input_dir.normalized().dot(Vector2.DOWN) > cos(PI/2.0):
				active_layer = up_layer
			elif input_dir.normalized().dot(Vector2.UP) > cos(PI/2.0):
				active_layer = down_layer
			else:
				active_layer = null
		else:
			active_layer = null
	else:
		selected_layer.handle_stick_input(input_dir)
