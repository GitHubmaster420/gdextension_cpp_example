extends ColorRect
class_name MousePieMenu


var selected := -1:
	set(v):
		if selected == v:
			return
		selected = v
		(material as ShaderMaterial).set_shader_parameter("selected_chunk", selected)
		

var amount : int

func _ready() -> void:
	visible = false
	amount = get_child_count()
	(material as ShaderMaterial).set_shader_parameter("chunks", amount)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseMotion:
		var pos :Vector2 = event.position
		var diff := pos - position - size / 2.0
		var angle := fposmod(-diff.angle() + PI / 2.0, TAU)
		var angle_divisor := TAU / float(amount)
		selected = int(angle / angle_divisor)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if selected >= 0:
				(get_child(selected) as MenuLabel).select()
