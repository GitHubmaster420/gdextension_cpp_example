extends ColorRect
class_name ClampedBezierEditor

@export var clamped_bezier : ClampedCubicBezier
@export var line_2d: Line2D

@export var point_count := 100

@export var bezier_tangent: BezierTangent
@export var bezier_tangent_2: BezierTangent


var size_at_start : Vector2
var pos_at_start : Vector2

var left_bottom : Vector2:
	get:
		return Vector2(0, size.y)

var right_top : Vector2:
	get:
		return Vector2(size.x, 0)

signal selected_set(is_selected : bool)

var selected := false:
	set(v):
		selected = v
		selected_set.emit(selected)

var hovered := false:
	set(v):
		hovered = v
		if hovered:
			color.a = 0.5
		else:
			color.a = 0.15

func _ready() -> void:
	size_at_start = size
	pos_at_start = position
	clamped_bezier.changed.connect(visaulize_curve)
	resized.connect(visaulize_curve)
	clamped_bezier.bake()
	visaulize_curve()
	
	mouse_entered.connect(func(): hovered = true)
	mouse_exited.connect(func(): hovered = false)

func _process(delta: float) -> void:
	if bezier_tangent.selected:
		clamped_bezier.start_angle = (right_top - left_bottom).angle_to(get_local_mouse_position() - left_bottom)
	if bezier_tangent_2.selected:
		clamped_bezier.end_angle = (left_bottom - right_top).angle_to(get_local_mouse_position() - right_top)
	clamped_bezier.end_angle += bezier_tangent_2.delta_angle
	bezier_tangent.position = left_bottom + ((right_top - left_bottom) * 0.25).rotated(clamped_bezier.start_angle)
	bezier_tangent_2.position = right_top + ((left_bottom - right_top) * 0.25).rotated(clamped_bezier.end_angle)
	
	
	
func visaulize_curve():
	if not is_inside_tree():
		return
	if not clamped_bezier or not line_2d:
		return

	var pts := PackedVector2Array()

	for i in range(point_count + 1):
		var t := float(i) / point_count
		var y := clamped_bezier.interpolate_baked(t)
		var p := Vector2(t * size.x, (1.0 - y) * (size.y))
		pts.append(p)

	line_2d.points = pts

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				selected = not selected
