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
		var new := kf.duplicate(15 & ~DuplicateFlags.DUPLICATE_SIGNALS)
		var h := copied_keyframe_holders[kf]
		print("old time: ", new.time)
		new.time += master_time.time - time_when_copied
		print("new time: ", new.time)
		h.paste_keyframe(new)

func paste_flipped():
	print("pasting flipped")
	for kf in copied_keyframe_holders:
		var new := kf.duplicate(15 & ~DuplicateFlags.DUPLICATE_SIGNALS)
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
