@abstract class_name Animator extends Node3D

const PREV_POSE_COLOR := Color(0.965, 0.899, 0.0, 1.0)
const PREV_TANGENT_COLOR := Color(0.96, 0.56, 0.0, 1.0)

const NEXT_POSE_COLOR := Color(0.51, 0.615, 1.0, 1.0)
const NEXT_TANGENT_COLOR := Color(0.0, 0.755, 0.557, 1.0)

@abstract func select()
@abstract func deselect()

signal interp_mode_changed(interp_mode, animator : Animator)

signal set_next_keyframe
signal set_prev_keyframe

@export var is_prev_keyframe := false:
	set(v):
		is_prev_keyframe = v
		set_prev_keyframe.emit()
@export var is_next_keyframe := false:
	set(v):
		is_next_keyframe = v
		set_next_keyframe.emit()

@export var gizmo: Gizmo:
	set(v):
		if gizmo:
			gizmo.controllable = null
		gizmo = v
		var all_children := find_children("GizmoControllable")
		for c in all_children:
			c.gizmo = gizmo
		gizmo_set.emit(gizmo)
		visibility_changed.emit()
			

@export var interp_mode_pie_menu : MousePieMenu

signal gizmo_set(gizmo : Gizmo)

func select_pose():
	pass

func select_tangent():
	pass

@abstract func right_clicked_empty(pressed : bool)

func to_resource():
	pass
