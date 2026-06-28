extends ColorRect

@export var anim_track_holders : Dictionary[SelectorChild, AnimTrackHolder]

@export var master_time : MasterTime

@export var gizmo : Gizmo

var shift_selected_children : Dictionary[SelectorChild, bool]

@export var selected_child : SelectorChild:
	set(v):
		if selected_child:
			selected_child.color.v = 0.5
		selected_child = v
		if not is_node_ready():
			return
		if not selected_child:

			master_time.current_anim_track_holder = null
			gizmo.controllable = null
			return
		shift_selected_children[selected_child] = false
		for c in shift_selected_children:
			continue
			if shift_selected_children[c]:
				on_child_shift_clicked(c)
		master_time.current_anim_track_holder = anim_track_holders[selected_child]
		selected_child.color.v = 1.0

var hovered := false:
	set(v):
		hovered = v
		if hovered:
			color.a = 0.8
		else:
			color.a = 0.4

var selected := false:
	set(v):
		if selected == v:
			return
		selected = v
		if selected:
			shift_selected = false
		animation_player.play("selected", -1, 1.0 if selected else -1.0, not selected)

var shift_selected := false

@export var animation_player: AnimationPlayer

func _ready() -> void:
	selected_child = selected_child
	for c in anim_track_holders:
		shift_selected_children[c] = false
		c.clicked.connect(on_child_clicked)
		c.shift_clicked.connect(on_child_shift_clicked)
		c.mouse_entered.connect((func(h : SelectorChild):
			if h.color.v > 0.9:
				return
			h.color.v = 0.75
			).bind(c))
		c.mouse_exited.connect((func(h : SelectorChild):
			if h == selected_child:
				return
			if h.color.v > 0.9:
				return
			h.color.v = 0.5
			).bind(c))
		c.color.v = 0.5
		
	hovered = false
	mouse_entered.connect(func(): hovered = true)
	mouse_exited.connect(func(): hovered = false)
	
	

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.shift_pressed:
				return
			if not selected:
				selected = true
			else:
				if not shift_selected:
					selected_child = null
				selected = false

func on_child_clicked(child : SelectorChild):
	if selected:
		selected = false
	selected_child = child
	

func on_child_shift_clicked(child : SelectorChild):
	print("shift clicked v: ", child.color.v)
	if not shift_selected:
		shift_selected = true
	if child == selected_child:
		selected_child = null
		shift_selected_children[child] = false
	elif child.color.v < 0.95:
		child.color.v = 1.0
		anim_track_holders[child].visible = true
		anim_track_holders[child].mouse_filter = Control.MOUSE_FILTER_IGNORE
		shift_selected_children[child] = true
	else:
		print("shift deselected")
		child.color.v = 0.5
		shift_selected_children[child] = false
		anim_track_holders[child].visible = false
