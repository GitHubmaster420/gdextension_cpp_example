extends Node

@export var master_time : MasterTime
@export var anim_track_holders : Array[AnimTrackHolder]

var copied_keyrfame_times : Dictionary[Keyframe, float]

var time_when_copied : float

@export var right_foot_anim_track_holder : AnimTrackHolder
@export var left_foot_anim_track_holder : AnimTrackHolder
@export var right_hand_anim_track_holder : AnimTrackHolder
@export var left_hand_anim_track_holder : AnimTrackHolder

func paste():
	for kf in copied_keyrfame_times:
		var new := kf.duplicate()
		var h := (kf.get_parent() as AnimTrackHolder)
		print("old time: ", new.time)
		new.time += master_time.time - time_when_copied
		print("new time: ", new.time)
		h.paste_keyframe(new)

func paste_flipped():
	pass

func copy():
	copied_keyrfame_times = {}
	time_when_copied = master_time.time
	copied_keyrfame_times = {}
	for h in anim_track_holders:
		var start := h.time
		for lassoed in h.lasso_selected_keyframes:
			copied_keyrfame_times[lassoed] = start
			

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
