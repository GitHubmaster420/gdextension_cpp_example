extends Node3D
class_name JoyCon

signal y_just_pressed
signal b_just_pressed
signal x_just_pressed
signal a_just_pressed
signal zr_just_pressed
signal r_just_pressed
var foot_id : int
var basis_at_start : Basis

var reference_basis : Basis
var joycon_basis := Basis()

var calibrated := false

var zr_pressed := false
var r_pressed := false
var a_pressed := false
var b_pressed := false
var y_pressed := false
var x_pressed := false

var is_right_joycon := true

var input_dir := Vector2.ZERO

func swap_accel_axes(a: Vector3) -> Vector3:

	return Vector3(-a.y, -a.z, a.x)# if is_right_joycon else Vector3(-a.y, a.z, -a.x)
	

var attachment : JoyConAttachment:
	set(value):
		if attachment == value: return
		attachment = value
		if not attachment: return
		if attachment.joy_con:
			attachment.detatch_joycon()
		attachment.attach_joycon(self)

signal basis_updated

var acceleration : Vector3

var upcoming_calibration := false

var world : World

func calibrate():
	if attachment:
		attachment.calibrate_joycon()

func _ready() -> void:
	if get_tree().current_scene is not World:
		return
	world = get_tree().current_scene
	world.add_joycon(self)


func _physics_process(delta: float) -> void:
	if get_meta("gyro_s", false) and get_meta("acc", false):
		update_joycon(get_meta("gyro_s"), get_meta("acc"), delta)
	if get_meta("buttons", false):
		handle_inputs(get_meta("buttons"))
	if get_meta("stick", false):
		handle_stick_state(get_meta("stick")["stick"])
		

func update_joycon(gyro_s : Vector3, acc : Vector3, dt : float):
	var omega_original := deg_to_rad(1.0) * gyro_s
	var omega_local := swap_accel_axes(omega_original)
	var omega_delta := omega_local * dt
	var omega_translated := omega_delta * reference_basis
	var omega_quat := Quaternion.from_euler(omega_translated) 
	joycon_basis = Quaternion(joycon_basis) * omega_quat
	var relative_rotation := joycon_basis
	global_basis = relative_rotation * basis_at_start
	acceleration = swap_accel_axes(acc)


func handle_inputs(buttons : Dictionary):
	if not y_pressed and (buttons.y or buttons.left):
		y_just_pressed.emit()
	y_pressed = buttons.y or buttons.left
	if not a_pressed and (buttons.a or buttons.right):
		a_just_pressed.emit()
	a_pressed = buttons.a or buttons.right
	if not x_pressed and (buttons.x or buttons.up):
		x_just_pressed.emit()
	x_pressed = buttons.x or buttons.up
	if not b_pressed and (buttons.b or buttons.down):
		b_just_pressed.emit()
	b_pressed = buttons.b or buttons.down
	if not zr_pressed and(buttons.zr or buttons.zl):
		if a_pressed:
			if self == world.active_joycon:
				print("calibrating")
				for jc in world.joycons:
					jc.calibrate()
					
			else:
				print("active jc: ", world.active_joycon, ", self: ", self)
		zr_just_pressed.emit()
	zr_pressed = buttons.zr or buttons.zl
	if not r_pressed and (buttons.r or buttons.l):
		r_just_pressed.emit()
	r_pressed = buttons.r or buttons.l
	

func handle_stick_state(stick_coords : Vector2):
	input_dir = stick_coords
