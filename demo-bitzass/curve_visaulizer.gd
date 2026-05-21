@tool
extends Node2D

@export var curve: MyCurve:
	set(v):
		if curve == v:
			return
		if curve:
			curve.changed.disconnect(_on_curve_changed)
			curve.t_set.disconnect(interpolate_t)
		curve = v
		if curve:
			curve.changed.connect(_on_curve_changed)
			curve.t_set.connect(interpolate_t)
		update_view()

@export var size := Vector2(200, 200):
	set(v):
		size = v
		update_view()

@export var point_count := 64:
	set(v):
		point_count = max(2, v)
		update_view()

@export var line: Line2D


func _ready():
	if not line:
		line = Line2D.new()
		line.name = "Line2D"
		add_child(line)
		line.owner = self
	if curve:
		curve.changed.connect(_on_curve_changed)
	update_view()

func interpolate_t(t : float):
	var vy := curve.interpolate_baked(t)
	var v := Vector2(t, vy)
	$MeshInstance2D.position = v * Vector2(size.x, -size.y)

func _on_curve_changed():
	update_view()

func update_view():
	if not is_inside_tree():
		return
	if not curve or not line:
		return

	var pts := PackedVector2Array()

	for i in range(point_count + 1):
		var t := float(i) / point_count
		var y := curve.interpolate_baked(t)
		var p := Vector2(t * size.x, -y * size.y)
		pts.append(p)

	line.points = pts
