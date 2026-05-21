extends Camera3D

var pivot : Node3D:
	get:
		return get_parent_node_3d()

var mid_pressed : bool

var mode := Mode.ROTATE

var ctrl_pressed := false
var shift_pressed := false

enum Mode{
	GRAB,
	ROTATE,
	ZOOM
	}

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print()
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			mid_pressed = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			global_position += global_basis.z * 0.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			global_position -= global_basis.z * 0.1
		
	if event is InputEventMouseMotion:
		if not mid_pressed:
			return
		match mode:
			Mode.GRAB:
				pivot.position += pivot.global_basis.x * -event.velocity.x * 0.0001 + pivot.global_basis.y * event.velocity.y * 0.0001
			Mode.ROTATE:
				pivot.rotate_y(-event.velocity.x * 0.0002)
				pivot.rotation.x = clampf(pivot.rotation.x - event.velocity.y * 0.0002, -PI * 0.3, PI * 0.3)
			Mode.ZOOM:
				global_position += global_basis.z * event.velocity.y * 0.0002
	if event is InputEventKey:
		if event.keycode == KEY_CTRL:
			ctrl_pressed = event.pressed
			if ctrl_pressed:
				mode = Mode.ZOOM
			else:
				if shift_pressed:
					mode = Mode.GRAB
				else:
					mode = Mode.ROTATE
		elif event.keycode == KEY_SHIFT:
			shift_pressed = event.pressed
			if shift_pressed:
				mode = Mode.GRAB
			
			else:
				if ctrl_pressed:
					mode = Mode.ZOOM
				else:
					mode = Mode.ROTATE
	
		
