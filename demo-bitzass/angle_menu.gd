@tool
extends ColorRect
class_name AngleMenu

signal angle_set

var selected := false

var hovered := false:
	set(v):
		hovered = v
		color.a = 0.1 if not hovered else 0.3

@export_range(1, 179) var default_angle := 90.0

@export var radius := 100.0:
	set(v):
		radius = v
		size = Vector2(1, 2) * radius
		queue_redraw()
		
@export var circle: ColorRect

@export_range(1, 179) var angle := 90.0:
	set(v):
		angle = v
		if not is_node_ready():
			return
		circle.position = size * Vector2(sin(deg_to_rad(angle)), (1.0 - cos(deg_to_rad(angle))) * 0.5) - circle.size / 2.0
		queue_redraw()
		angle_set.emit()

func _ready() -> void:
	circle.gui_input.connect(on_circle_gui)
	mouse_entered.connect(func(): hovered = true)
	mouse_exited.connect(func(): hovered = false)
	angle = angle
	radius = radius
	visibility_changed.connect(func():
		if not visible:
			return
		queue_redraw())



func on_circle_gui(event : InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			selected = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			selected = false
	if event is InputEventKey:
		if not hovered:
			return
		if event.pressed and (event.keycode == KEY_G or event.keycode == KEY_R) and event.alt_pressed:
			angle = default_angle

func _draw() -> void:
	#var quat:= Quaternion.from_euler(Vector3(randf_range(-PI,PI), randf_range(-PI,PI), randf_range(-PI,PI)))
	#print("quat: ", quat,", x flipped quat: ", QuaternionExtender.mirror(quat))
	draw_line(Vector2(0, size.y / 2.0), Vector2.ZERO, Color.MAGENTA, 5)
	draw_line(Vector2(0, size.y / 2.0), circle.position + circle.size / 2.0, Color.AQUA, 5)

func _physics_process(delta: float) -> void:
	if selected:
		angle = clampf(rad_to_deg((get_local_mouse_position() - Vector2(0, size.y / 2.0)).angle()) + 90, 1, 179)
