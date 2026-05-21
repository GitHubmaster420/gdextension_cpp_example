@tool
extends Area2D
class_name FilterArea

@onready var gizmo: Gizmo = %Gizmo


var selected := false:
	set(v):
		selected = v
		if not is_node_ready():
			return
		if selected:
			(get_parent() as CanvasItem).modulate.v = 1.0
			for area in filter_areas:
				if area != self:
					area.selected = false
			gizmo.controllable = controllable
		
			
		else:
			(get_parent() as CanvasItem).modulate.v = 0.5

var hovered := false:
	set(v):
		hovered = v
		if not is_node_ready():
			return
		if not hovered:
			(get_parent() as CanvasItem).modulate.a = 0.3
		else:
			(get_parent() as CanvasItem).modulate.a = 1.0

static var filter_areas : Array[FilterArea]

@export var controllable : GizmoControllable

func _ready() -> void:
	input_pickable = true
	input_event.connect(_input_event_clicked)
	hovered = false
	selected = false
	filter_areas.append(self)

func _mouse_enter() -> void:
	hovered = true

func _mouse_exit() -> void:
	hovered = false



func _input_event_clicked(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				selected = not selected
				if not selected:
					gizmo.controllable = null
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				print("right clicked")
