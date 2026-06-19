extends Node

enum{
	GIZMO_TRANSFORM
}

var undo_history : Array[Dictionary]

var event_history : Array[Dictionary]

@export var gizmo : Gizmo

var latest_gizmoable : Dictionary

func _ready() -> void:
	gizmo.pressed.connect(on_gizmo_pressed)
	gizmo.released.connect(on_gizmo_released)

func on_gizmo_pressed():
	if not gizmo.controllable:
		return
	latest_gizmoable = {}
	latest_gizmoable["type"] = GIZMO_TRANSFORM
	latest_gizmoable["start_tr"] = gizmo.controllable.control_node.global_transform
	latest_gizmoable["controllable"] = gizmo.controllable
	latest_gizmoable["object"] = gizmo.controllable.control_node
	
func on_gizmo_released():
	if not gizmo.controllable or latest_gizmoable.is_empty():
		return
	latest_gizmoable["end_tr"] = latest_gizmoable["object"].global_transform
	event_history.append(latest_gizmoable)
	undo_history.clear()
	latest_gizmoable = {}

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_Z and event.pressed:
			if event.ctrl_pressed:
				if event.shift_pressed:
					redo()
				else:
					undo()

func undo():
	if event_history.size() == 0:
		return
	var latest : Dictionary = event_history.pop_back()
	match latest["type"]:
		GIZMO_TRANSFORM:
			(latest["controllable"] as GizmoControllable).gizmo = null
			gizmo.controllable = null
			latest["object"].global_transform = latest["start_tr"]
	undo_history.append(latest)
			

func redo():
	if undo_history.size() == 0:
		return
	var latest : Dictionary = undo_history.pop_back()
	match latest["type"]:
		GIZMO_TRANSFORM:
			(latest["controllable"] as GizmoControllable).gizmo = null
			gizmo.controllable = null
			latest["object"].global_transform = latest["end_tr"]
