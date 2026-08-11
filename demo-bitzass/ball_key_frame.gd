extends TextureRect
class_name BallKeyFrame

@export var time : float

@export var pos : Marker3D
@export var in_tangent : Marker3D
@export var out_tangent : Marker3D

@export var pos_controllable : GizmoControllable
@export var in_controllable : GizmoControllable
@export var out_controllable : GizmoControllable

@export var parent_container : BallKeyFrames

var moving := false

var selected := false:
	set(v):
		selected = v
		if not selected:
			modulate = Color.WHITE
		else:
			modulate = Color.AQUA

@export var gizmo : Gizmo

@export var current := 0:
	set(v):
		current = v
		if current > 2:
			current = 0
		if current < 0:
			current = 2
		if not is_node_ready():
			return
		match current:
			0:
				gizmo.controllable = pos_controllable
			1:
				gizmo.controllable = out_controllable
			2:
				gizmo.controllable = in_controllable
			

func _ready() -> void:
	if not pos:
		pos = Marker3D.new()
		add_child(pos)
		pos.name = "Pos"
		pos.owner = owner
		var gc := GizmoControllable.new()
		gc.grabbable = true
		gc.name = "GizmoControllable"
		pos.add_child(gc)
		pos_controllable = gc
		
	if not in_tangent:
		in_tangent = Marker3D.new()
		pos.add_child(in_tangent)
		in_tangent.name = "InTangent"
		in_tangent.owner = owner
		var gc := GizmoControllable.new()
		gc.grabbable = true
		gc.name = "GizmoControllable"
		in_tangent.add_child(gc)
		in_controllable = gc
		var s := Stretcher.new()
		s.start_stretch = pos
		s.end_stretch = in_tangent
		add_child(s)
		s.material_override = StandardMaterial3D.new()
		(s.material_override as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		(s.material_override as StandardMaterial3D).albedo_color = Color.RED
	if not out_tangent:
		out_tangent = Marker3D.new()
		pos.add_child(out_tangent)
		out_tangent.name = "OutTangent"
		out_tangent.owner = owner
		var gc := GizmoControllable.new()
		gc.grabbable = true
		gc.name = "GizmoControllable"
		out_tangent.add_child(gc)
		out_controllable = gc
		var s := Stretcher.new()
		s.start_stretch = pos
		s.end_stretch = out_tangent
		add_child(s)
		s.material_override = StandardMaterial3D.new()
		(s.material_override as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		(s.material_override as StandardMaterial3D).albedo_color = Color.GREEN
	visibility_changed.connect(func():
		for c in get_children():
			if c is Node3D:
				c.visible = is_visible_in_tree()
		
		)

func _process(delta: float) -> void:
	if moving:
		var mp := parent_container.get_local_mouse_position().x
		mp = clampf(mp, 0, parent_container.master_time.size.x)
		time = remap(mp, 0, parent_container.master_time.size.x, 0, parent_container.master_time.max_time)
		position.x = mp - size.x / 4.0
		parent_container.sort_ks()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (not event.pressed) and event.button_index == MOUSE_BUTTON_LEFT:
			moving = false
	if not selected:
		return
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_D:
				current += 1
			if event.keycode == KEY_A:
				current -= 1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			moving = true
