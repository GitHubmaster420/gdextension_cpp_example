@tool
extends StickOption
class_name StickLayer

var stick_ui : StickUI:
	set(v):
		for c in get_children():
			DuckTyper.set_variable_duck_typed(c, "stick_ui", v)

var active_sub_layer : StickOption:
	set(v):
		if active_sub_layer:
			active_sub_layer.deactivate()
		active_sub_layer = v
		if active_sub_layer:
			active_sub_layer.activate()
		

var selected_sub_layer : StickOption

@export_enum("up_layer_node") var up_layer_node : String:
	set(v):
		up_layer_node = v
		if v:
			up_layer = get_node_or_null(v)
@export_enum("down_layer_node") var down_layer_node : String:
	set(v):
		down_layer_node = v
		if v:
			down_layer = get_node_or_null(v)
@export_enum("right_layer_node") var right_layer_node : String:
	set(v):
		right_layer_node = v
		if v:
			right_layer = get_node_or_null(v)
@export_enum("left_layer_node") var left_layer_node : String:
	set(v):
		left_layer_node = v
		if v:
			left_layer = get_node_or_null(v)
@export_enum("middle_layer_node") var middle_layer_node : String:
	set(v):
		middle_layer_node = v
		if v:
			middle_layer = get_node_or_null(v)
@export var up_layer : StickOption
@export var down_layer : StickOption
@export var right_layer : StickOption
@export var left_layer : StickOption
@export var middle_layer : StickOption

func _validate_property(property: Dictionary) -> void:
	if property.name == "up_layer_node":
		property.hint = PROPERTY_HINT_ENUM
		var names : Array[String]
		for c in get_children():
			names.append(c.name)
		property.hint_string = ",".join(names)
	if property.name == "down_layer_node":
		property.hint = PROPERTY_HINT_ENUM
		var names : Array[String]
		for c in get_children():
			names.append(c.name)
		property.hint_string = ",".join(names)
	if property.name == "right_layer_node":
		property.hint = PROPERTY_HINT_ENUM
		var names : Array[String]
		for c in get_children():
			names.append(c.name)
		property.hint_string = ",".join(names)
	if property.name == "left_layer_node":
		property.hint = PROPERTY_HINT_ENUM
		var names : Array[String]
		for c in get_children():
			names.append(c.name)
		property.hint_string = ",".join(names)
	if property.name == "middle_layer_node":
		property.hint = PROPERTY_HINT_ENUM
		var names : Array[String]
		for c in get_children():
			names.append(c.name)
		property.hint_string = ",".join(names)
		

const QUARTER_DOT_PRODUCT = cos(PI/4.0)

func select():
	deactivate()
	for c : StickOption in get_children():
		c.select()

func deselect():
	for c : StickOption in get_children():
		c.deselect()

func on_zr_pressed():
	if selected_sub_layer:
		selected_sub_layer.on_zr_pressed()
		return
	if active_sub_layer:
		deselect()
		active_sub_layer.select()
		selected_sub_layer = active_sub_layer

func on_y_pressed(jc : JoyCon):
	if not selected_sub_layer:
		return
	selected_sub_layer.on_y_pressed(jc)

func on_b_pressed():
	if selected_sub_layer:
		if selected_sub_layer is StickLayer:
			if not selected_sub_layer.selected_sub_layer:
				#selected_sub_layer.deselect()
				select()
				selected_sub_layer = null
				#activate()
		else:
			selected_sub_layer = null
			select()
			#activate()
	if selected_sub_layer:
		DuckTyper.call_func_duck_typed(selected_sub_layer, "on_b_pressed")
		

func turn_on():
	if selected_sub_layer:
		selected_sub_layer.turn_on()
		return
	for c : StickOption in get_children():
		c.turn_on()

func turn_off():
	if selected_sub_layer:
		selected_sub_layer.turn_off()
		return
	for c : StickOption in get_children():
		c.turn_off()

func activate():
	for c : StickOption in get_children():
		c.activate()
		
func deactivate():
	for c : StickOption in get_children():
		c.deactivate()

func handle_stick_input(v : Vector2):
	if selected_sub_layer:
		DuckTyper.call_func_duck_typed(selected_sub_layer, "handle_stick_input", v)
	else:
		if v.length_squared() < 0.25:
			active_sub_layer = middle_layer
		elif v.normalized().dot(Vector2.DOWN) > QUARTER_DOT_PRODUCT:
			active_sub_layer = up_layer
		elif v.normalized().dot(Vector2.RIGHT) > QUARTER_DOT_PRODUCT:
			active_sub_layer = right_layer
		elif v.normalized().dot(Vector2.UP) > QUARTER_DOT_PRODUCT:
			active_sub_layer = down_layer
		else:
			active_sub_layer = left_layer
		
