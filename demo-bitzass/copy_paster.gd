extends Node

@export var master_time : MasterTime
@export var anim_track_holders : Array[AnimTrackHolder]

var copied_keyframe_holders : Dictionary[Keyframe, AnimTrackHolder]

var time_when_copied : float

@export var right_foot_anim_track_holder : AnimTrackHolder
@export var left_foot_anim_track_holder : AnimTrackHolder
@export var right_hand_anim_track_holder : AnimTrackHolder
@export var left_hand_anim_track_holder : AnimTrackHolder

func paste():
	for kf in copied_keyframe_holders:
		var new : Keyframe = kf.duplicate()
		var all_children := new.animator.find_children("*", "MeshInstance3D")
		for m : MeshInstance3D in all_children:
			m.set_surface_override_material(0, m.get_active_material(0).duplicate(true))
		for c in new.animator.get_property_list():
			if "curve" not in c.name:
				continue
			print("c name: ", c.name)
			var r = new.animator.get(c.name)
			if r is not Resource:
				continue
			new.animator.set(c.name, r.duplicate(true))
		var h := copied_keyframe_holders[kf]
		print("old time: ", new.time)
		new.time += master_time.time - time_when_copied
		print("new time: ", new.time)
		h.paste_keyframe(new)

func paste_flipped():
	print("pasting flipped")
	for kf in copied_keyframe_holders:
		var new : Keyframe = kf.duplicate()
		var all_children := new.animator.find_children("*", "MeshInstance3D")
		for m : MeshInstance3D in all_children:
			m.set_surface_override_material(0, m.get_active_material(0).duplicate(true))
		for c in new.animator.get_property_list():
			if "curve" not in c.name:
				continue
			print("c name: ", c.name)
			var r = new.animator.get(c.name)
			if r is not Resource:
				continue
			new.animator.set(c.name, r.duplicate(true))
		var h := copied_keyframe_holders[kf]
		var new_h := h
		if h == right_foot_anim_track_holder:
			new_h = left_foot_anim_track_holder
		elif h == left_foot_anim_track_holder:
			new_h = right_foot_anim_track_holder
		elif h == right_hand_anim_track_holder:
			new_h = left_hand_anim_track_holder
		elif h == left_hand_anim_track_holder:
			new_h = right_hand_anim_track_holder
		new.time += master_time.time - time_when_copied
		new_h.paste_flipped(new)

func copy():
	copied_keyframe_holders = {}
	time_when_copied = master_time.time
	for h in anim_track_holders:
		var start := h.time
		for lassoed in h.lasso_selected_keyframes:
			copied_keyframe_holders[lassoed] = h
			

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.ctrl_pressed:
			if event.keycode == KEY_C:
				copy()
			elif event.keycode == KEY_V:
				if event.shift_pressed:
					paste_flipped()
				else:
					paste()
