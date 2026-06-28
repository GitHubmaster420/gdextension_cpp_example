extends Node

var undo_history : Array[Command]

var event_history : Array[Command]

@export var gizmo : Gizmo

var latest_transform_command : EditTransform

@export var anim_track_holders : Array[AnimTrackHolder]

func _ready() -> void:
	gizmo.pressed.connect(on_gizmo_pressed)
	gizmo.released.connect(on_gizmo_released)
	
	for h in anim_track_holders:
		h.keyframe_deleted.connect(on_keyframe_deleted.bind(h))
		h.keyframe_added.connect(on_keyframe_added.bind(h))

func on_gizmo_pressed():
	if not gizmo.controllable:
		return
		
	latest_transform_command = EditTransform.new()
	latest_transform_command.gizmo = gizmo
	latest_transform_command.controllable = gizmo.controllable
	latest_transform_command.control_node = gizmo.controllable.control_node
	latest_transform_command.start_tr = latest_transform_command.control_node.global_transform
	#latest_gizmoable = {}
	#latest_gizmoable["type"] = GIZMO_TRANSFORM
	#latest_gizmoable["start_tr"] = gizmo.controllable.control_node.global_transform
	#latest_gizmoable["controllable"] = gizmo.controllable
	#latest_gizmoable["object"] = gizmo.controllable.control_node

func on_event(command : Command):
	event_history.append(command)
	undo_history.clear()

func on_gizmo_released():
	if not gizmo.controllable or not latest_transform_command:
		return
	latest_transform_command.end_tr = latest_transform_command.control_node.global_transform
	on_event(latest_transform_command)
	latest_transform_command = null
	#latest_gizmoable["end_tr"] = latest_gizmoable["object"].global_transform
	#event_history.append(latest_gizmoable)
	#undo_history.clear()
	#latest_gizmoable = {}

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
	var latest : Command = event_history.pop_back()
	latest.undo()
	undo_history.append(latest)
			

func redo():
	if undo_history.size() == 0:
		return
	var latest : Command = undo_history.pop_back()
	latest.redo()
	event_history.append(latest)

@abstract class Command:
	@abstract func undo()
	@abstract func redo()

class EditTransform extends Command:
	var start_tr : Transform3D
	var end_tr : Transform3D
	var controllable : GizmoControllable
	var control_node : Node3D
	var gizmo : Gizmo
	func undo():
		gizmo.controllable = null
		control_node.global_transform = start_tr
		gizmo.controllable = controllable
	func redo():
		gizmo.controllable = null
		control_node.global_transform = end_tr
		gizmo.controllable = controllable

func on_keyframe_deleted(kf : Keyframe, holder : AnimTrackHolder):
	var command := DeleteKeyframe.new()
	command.keyframe = kf
	command.anim_track_holder = holder
	on_event(command)

class DeleteKeyframe extends Command:
	var keyframe : Keyframe
	var anim_track_holder : AnimTrackHolder
	func undo():
		anim_track_holder.un_delete_keyframe(keyframe)
	func redo():
		anim_track_holder.delete_keyframe(keyframe)

func on_keyframe_added(kf : Keyframe, holder : AnimTrackHolder):
	var command := AddKeyframe.new()
	command.keyframe = kf
	command.anim_track_holder = holder
	on_event(command)

class AddKeyframe extends Command:
	var keyframe : Keyframe
	var anim_track_holder : AnimTrackHolder
	func undo():
		anim_track_holder.delete_keyframe(keyframe)
	func redo():
		anim_track_holder.un_delete_keyframe(keyframe)
