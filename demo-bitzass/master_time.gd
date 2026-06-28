extends ColorRect
class_name MasterTime
@export var current_time_label: ColorRect

var mouse_pressed := false
var timeline_selected := false:
	set(v):
		timeline_selected = v
		if current_anim_track_holder:
			current_anim_track_holder.timeline_selected = timeline_selected

@export var max_time_input: LineEdit

var playing := false

var time := 0.0:
	set(v):
		time = v
		if not is_node_ready():
			return
		current_time_label.position.x = remap(snapped(time, 1.0/30.0), 0, max_time, 0, size.x)
		for holder in anim_track_holders:
			holder.time = time

@export var max_time := 2.0:
	set(v):
		max_time = snappedf(v, 1.0/30.0)
		if not is_node_ready():
			return
		for h in anim_track_holders:
			h.max_time = max_time
		time = time

@export var anim_track_holders : Array[AnimTrackHolder]
var current_anim_track_holder : AnimTrackHolder:
	set(v):
		for h in anim_track_holders:
			h.playing = false
			h.visible = true
			h.visible = false
		if current_anim_track_holder:
			current_anim_track_holder.timeline_selected = false
		if current_anim_track_holder == v:
			if current_anim_track_holder:
				current_anim_track_holder.visible = true
				color.a = 0
			else:
				color.a = 1
			return
		
		current_anim_track_holder = v
		if not current_anim_track_holder:
			color.a = 1
			return
		color.a = 0
		#current_anim_track_holder.mouse_filter = Control.MOUSE_FILTER_STOP
		playing = false
		current_anim_track_holder.visible = true
		#visible = false

func _ready() -> void:
	for h in anim_track_holders:
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	max_time_input.text = str(max_time)
	max_time_input.text_submitted.connect(func(new : String):
		if not new.is_valid_float():
			return
		max_time = float(new)
		)
	max_time = max_time

func _gui_input(event: InputEvent) -> void:
	for h in anim_track_holders:
		if not h.visible:
			continue
		h._gui_input(event)
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				timeline_selected = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			timeline_selected = false
	if not visible:
		return
	if event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed:
			playing = not playing

func _process(delta: float) -> void:
	if playing:
		time += delta
		if time > max_time:
			time = 0
	var mouse_pos_clamped := clampf(get_local_mouse_position().x, 0, size.x)
	if timeline_selected:
		time = snapped(remap(mouse_pos_clamped, 0, size.x, 0, max_time), 1.0 / 30.0)
