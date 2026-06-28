extends Animator
class_name RootAnimator

var current := 0

@export var gizmo_controllable: GizmoControllable

@export var root: Marker3D


func _ready() -> void:
	gizmo_set.connect(on_gizmo_set)

func on_gizmo_set(_gizmo : Gizmo):
	gizmo_controllable.gizmo = _gizmo
	if _gizmo:
		_gizmo.controllable = gizmo_controllable

func select():
	pass

func deselect():
	pass

func right_clicked_empty(pressed : bool):
	pass
