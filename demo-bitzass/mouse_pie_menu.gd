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
		
		var angle := atan2(diff.y, -diff.x)
		var angle_divisor := PI * 2.0 / float(amount)
		var angle_pos := angle + PI
		selected = int(angle_pos / angle_divisor + 0.5) % amount
		
		if diff.length() > size.x / 2.0:
			selected = -1
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if selected >= 0:
				(get_child(selected) as MenuLabel).select()
			else:
				visible = false
