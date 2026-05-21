class_name GizmoControllable
extends Node

var control_node : Node3D:
	get:
		return get_parent() as Node3D

@export var grabbable := false

@export var gizmo: Gizmo

var ignore := false:
	set(v):
		ignore = v
		if ignore:
			current = 0

var ignore_time := 0.05
var current := 0.0

func alt_g_pressed():
	DuckTyper.call_func_duck_typed(get_parent(), "alt_g_pressed")

func alt_r_pressed():
	if DuckTyper.call_func_duck_typed(get_parent(), "alt_r_pressed"):
		gizmo.controllable = null
		await get_tree().create_timer(0.05).timeout
		gizmo.controllable = self

func _process(delta: float) -> void:
	if not gizmo:
		return
	if gizmo.controllable != self:
		return
	if ignore:
		current += delta
		if current > ignore_time:
			ignore = false
		return
	if grabbable:
		control_node.global_transform = gizmo.global_transform
	else:
		control_node.global_basis = gizmo.global_basis
