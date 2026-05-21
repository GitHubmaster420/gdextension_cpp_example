@tool
extends ColorRect
class_name AnimTrackHolder

@export var is_right := true

var playing := false

signal keyframe_added(kf : Keyframe)

@export var empty_canvas : EmptyCanvas
signal time_changed(t : float)
@export var time : float:
	set(v):
		time = v
		if not is_node_ready():
			return
		current_time_label.position.x = remap(snapped(time, 1.0/30.0), 0, max_time, 0, size.x)
		time_changed.emit(time)

@export var current_time_label: ColorRect

@export var keyframes : Array[Keyframe]

var hovered_key : Keyframe
var selected_key : Keyframe
var edited_key : Keyframe:
	set(v):
		if edited_key:
			edited_key.animator.gizmo = null
			edited_key.color = Color.WHITE
			edited_key.animator.deselect()
		edited_key = v
		if not edited_key:
			return
		edited_key.animator.gizmo = gizmo
		edited_key.animator.current = edited_key.animator.current
		edited_key.color = Color.AQUA
		edited_key.animator.select()
		
var prev_key : Keyframe:
	set(v):
		if prev_key:
			if prev_key != next_key:
				prev_key.animator.visible = false
		prev_key = v
		if not prev_key: return
		prev_key.animator.visible = true
		if prev_key.animator is not FootAnimator:
			return
		var stored := (prev_key.animator as FootAnimator).pose_material.albedo_color.a
		(prev_key.animator as FootAnimator).pose_material.albedo_color = FootAnimator.PREV_POSE_COLOR
		(prev_key.animator as FootAnimator).tangent_material.albedo_color = FootAnimator.PREV_TANGENT_COLOR
		(prev_key.animator as FootAnimator).pose_material.albedo_color.a = stored
		(prev_key.animator as FootAnimator).tangent_material.albedo_color.a = stored
		
		

var next_key : Keyframe:
	set(v):
		if next_key:
			if next_key != prev_key:
				next_key.animator.visible = false
		next_key = v
		if not next_key: return
		if next_key.animator is not FootAnimator:
			return
		var stored := (next_key.animator as FootAnimator).pose_material.albedo_color.a
		(next_key.animator as FootAnimator).pose_material.albedo_color = FootAnimator.NEXT_POSE_COLOR
		(next_key.animator as FootAnimator).tangent_material.albedo_color = FootAnimator.NEXT_TANGENT_COLOR
		(next_key.animator as FootAnimator).pose_material.albedo_color.a = stored
		(next_key.animator as FootAnimator).tangent_material.albedo_color.a = stored
	
		next_key.animator.visible = true

@export_range(0.0, 10.0) var max_time : float = 10:
	set(v):
		max_time = v
		if not is_node_ready():
			return
		for k in keyframes:
			k.position.x = remap(k.time, 0, max_time, 0, size.x)


@export var gizmo : Gizmo
@export var animator : PackedScene

var mouse_pressed := false

var timeline_selected := false

var hovered := false:
	set(v):
		hovered = v
		if hovered:
			color.a = 1.0
		else:
			color.a = 0.5

var next_toggle := false:
	set(v):
		next_toggle = v
		if next_toggle:
			edited_key = next_key
		else:
			edited_key = prev_key

func _ready() -> void:
	max_time = max_time
	z_index = 100
	mouse_entered.connect(func(): hovered = true)
	mouse_exited.connect(func(): hovered = false)
	
	visibility_changed.connect(func():
		for k in keyframes:
			k.animator.visible = visible
			if not visible:
				edited_key = null
			else:
				edited_key = prev_key
				if not edited_key:
					edited_key = next_key

		)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				var mouse_pos : Vector2 = event.position
				add_keyframe(mouse_pos)
			elif event.button_index == MOUSE_BUTTON_LEFT:
				mouse_pressed = true
				if hovered and not hovered_key:
					timeline_selected = true
		elif event.button_index == MOUSE_BUTTON_LEFT:
			timeline_selected = false
			mouse_pressed = false
			selected_key = null
				

func add_keyframe(mouse_pos : Vector2):
	var new_key := Keyframe.new()
	add_child(new_key)
	keyframes.append(new_key)
	new_key.animator = animator.instantiate()
	DuckTyper.set_variable_duck_typed(new_key.animator, "is_right", is_right)
	if empty_canvas:
		empty_canvas.right_clicked.connect(new_key.animator.right_clicked_empty)
	new_key.add_child(new_key.animator)
	new_key.mouse_entered.connect((func(key : Keyframe):
		hovered_key = key
		key.color = Color.YELLOW
		key.hovered = true
		).bind(new_key))
	new_key.mouse_exited.connect((func(key : Keyframe):
		if key == hovered_key:
			hovered_key = null
			key.color = Color.WHITE
			key.hovered = false
			).bind(new_key))
	new_key.clicked.connect((func(was_clicked : bool, key : Keyframe):
		if was_clicked:
			selected_key = key
		elif selected_key == key:
			selected_key = null
		).bind(new_key))
		
	new_key.position.x = mouse_pos.x
	new_key.position.y = size.y / 2.0 - new_key.size.y / sqrt(2.0)
	if not selected_key:
		selected_key = new_key
	on_selected_key_moved()
	if not edited_key:
		edited_key = next_key
	keyframe_added.emit(new_key)
	


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_W:
				next_toggle = not next_toggle
			if event.keycode == KEY_SPACE:
				playing = not playing


	

func _process(delta: float) -> void:
	var mouse_pos_clamped := clampf(get_local_mouse_position().x, 0, size.x)
	if playing:
		time += delta
		if time > max_time:
			time = 0
	if selected_key:
		selected_key.position.x = mouse_pos_clamped
		on_selected_key_moved()
		sort_keyframes()
	elif timeline_selected:
		
		time = remap(mouse_pos_clamped, 0, size.x, 0, max_time)
		set_next_and_prev_keyframe()
	

func on_selected_key_moved():
	selected_key.time = snapped(remap(selected_key.position.x, 0, size.x, 0, max_time), 1.0 / 30.0)
	keyframes.sort_custom(func(a : Keyframe, b : Keyframe):
		return a.position.x < b.position.x
		)
	set_next_and_prev_keyframe()

func set_next_and_prev_keyframe():
	if keyframes.size() == 0:
		prev_key = null
		next_key = null
		return
	next_toggle = next_toggle
	prev_key = keyframes[-1]
	next_key = keyframes[-1]
	for i in range(1, keyframes.size()):
		if keyframes[i].position.x > current_time_label.position.x:
			prev_key = keyframes[i - 1]
			next_key = keyframes[i]
			break

func sort_keyframes():
	keyframes.sort_custom(func(a : Keyframe, b : Keyframe):
		return a.time < b.time
		)
	
