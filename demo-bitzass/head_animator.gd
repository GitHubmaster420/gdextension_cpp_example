extends Animator
class_name HeadAnimator

@export var chest: Marker3D
@export var neck: Marker3D
@export var head: Marker3D

@export var gizmo_controllables : Array[GizmoControllable]

var current_gizmoable : GizmoControllable:
	set(v):
		if current_gizmoable:
			current_gizmoable.gizmo = null
		current_gizmoable = v
		if not current_gizmoable:
			return
		current_gizmoable.gizmo = gizmo
		gizmo.controllable = current_gizmoable

var current := 0:
	set(v):
		current = v
		if current < 0:
			current = 1
		if current > 1:
			current = 0
		current_gizmoable = gizmo_controllables[current]
		

func select():
	pass
	
func deselect():
	pass

func right_clicked_empty(pressed : bool):
	pass

func _input(event: InputEvent) -> void:
	if not gizmo or not visible:
		return
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_D:
				current += 1
			if event.keycode == KEY_A:
				current -= 1
