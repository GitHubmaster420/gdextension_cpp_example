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

static func remap_var(value: Variant, map: Dictionary) -> Variant:
	if value is Node:
		return map.get(value, value)

	elif value is Array:
		var arr = value.duplicate()
		for i in arr.size():
			arr[i] = remap_var(arr[i], map)
		return arr

	elif value is Dictionary:
		var dict = {}
		for k in value:
			dict[remap_var(k, map)] = remap_var(value[k], map)
		return dict

	else:
		return value

static func duplicate_without_instantiation(animator : Animator) -> Animator:
	var this := animator
	var children := animator.find_children("*", "", true, false)
	var new : Animator
	if animator is FootAnimator:
		new = FootAnimator.new()
	elif animator is HandsAnimator:
		new = HandsAnimator.new()
	elif animator is SpineAnimator:
		new = SpineAnimator.new()
	elif animator is RootAnimator:
		new = RootAnimator.new()
	elif animator is HeadAnimator:
		new = HeadAnimator.new()
	else:
		assert(false)
	var new_children = children.duplicate(true)
	var new_and_old_parents : Dictionary[Node, Node]
	new_and_old_parents[animator] = new
	for i in range(new_children.size()):
		new_and_old_parents[children[i]] = new_children[i]
	
	for c in children:
		if c is AnimationCreator:
			continue
		var new_node := new_and_old_parents[c]
		if new_node.get_parent() == animator:
			var new_parent := new
			new_node.reparent(new_parent, new_node is Control)
	
	for old_node in new_and_old_parents:
		var new_node := new_and_old_parents[old_node]

		for p in old_node.get_property_list():
			if !(p.usage & PROPERTY_USAGE_STORAGE):
				continue

			new_node.set(
				p.name,
				remap_var(old_node.get(p.name), new_and_old_parents)
			)
		
	for p in this.get_property_list():
		if !(p.usage & PROPERTY_USAGE_STORAGE):
			continue

		new.set(p.name, remap_var(this.get(p.name), new_and_old_parents))
	return new
	
	
