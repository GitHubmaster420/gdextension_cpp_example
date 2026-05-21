extends ColorRect

@export var anim_track_holders : Dictionary[SelectorChild, AnimTrackHolder]

@export var master_time : MasterTime

@export var gizmo : Gizmo

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
		animation_player.play("selected", -1, 1.0 if selected else -1.0, not selected)
		
@export var animation_player: AnimationPlayer

func _ready() -> void:
	selected_child = selected_child
	for c in anim_track_holders:
		c.clicked.connect(on_child_clicked)
		c.mouse_entered.connect((func(h : SelectorChild):
			h.color.v = 0.75
			).bind(c))
		c.mouse_exited.connect((func(h : SelectorChild):
			if h == selected_child:
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
			if not selected:
				selected = true
			else:
				selected_child = null
				selected = false

func on_child_clicked(child : SelectorChild):
	if not selected:
		return
	selected_child = child
	
	selected = false
	
