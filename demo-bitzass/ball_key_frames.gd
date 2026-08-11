class_name BallKeyFrames
extends Control

@export var ball_ks : Array[BallKeyFrame]

@export var ball : MeshInstance3D

@export var master_time : MasterTime

@export var gizmo : Gizmo

@export var ball_tex : Texture2D

var active := false:
	set(v):
		active = v
		if not is_node_ready():
			return
		for k in ball_ks:
			k.visible = active
		

var next_toggle := false:
	set(v):
		next_toggle = v
		if not is_node_ready():
			return
		if ball_ks.size() == 0:
			return
		var current_time := master_time.time
		
		var next_idx := ball_ks.size() - 1
		
		for i in range(ball_ks.size() - 1):
			if ball_ks[i + 1].time > current_time:
				next_idx = i + 1
				break
		var prev_idx := next_idx - 1
		
		if next_toggle:
			active_key = ball_ks[next_idx]
		else:
			active_key = ball_ks[prev_idx]

var active_key : BallKeyFrame:
	set(v):
		if not is_node_ready():
			active_key = v
			return
		if active_key:
			active_key.selected = false
		active_key = v
		if not active_key:
			return
		active_key.selected = true
		active_key.current = active_key.current

func _ready() -> void:
	master_time.max_time_set.connect(func(time : float):
		for k in ball_ks:
			k.position.x = remap(k.time, 0, master_time.size.x, 0, time)
			k.position.x -= k.size.x / 2.0
		
		)
	active = false

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_W:
			next_toggle = not next_toggle

func _process(delta: float) -> void:
	if ball_ks.size() == 0:
		return
	elif ball_ks.size() == 1:
		ball.global_position = ball_ks[0].pos.global_position
	else:
		
		var current_time := master_time.time
		
		var next_idx := ball_ks.size() - 1
		
		for i in range(ball_ks.size() - 1):
			if ball_ks[i + 1].time > current_time:
				next_idx = i + 1
				break
		var prev_idx := next_idx - 1
		
		if ball_ks[prev_idx].time == ball_ks[next_idx].time:
			ball.global_position = ball_ks[prev_idx].pos.global_position
		else:
			var p := ball_ks[prev_idx]
			var n := ball_ks[next_idx]
			var t := remap(current_time, p.time, n.time, 0, 1)
			t = clampf(t, 0, 1)
			
			ball.global_position = p.pos.global_position.bezier_interpolate(p.out_tangent.global_position, n.in_tangent.global_position, n.pos.global_position, t)
			

func add_key(time : float):
	print("adding key")
	var k := BallKeyFrame.new()
	k.gizmo = gizmo
	k.time = time
	add_child(k)
	k.texture = ball_tex
	#k.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	k.scale = Vector2.ONE * 0.5
	k.position.x = remap(k.time, 0, master_time.max_time, 0, master_time.size.x)
	k.position.x -= k.size.x / 4.0
	k.position.y = (-k.size.y  - size.y) / 8.0
	k.z_index = 2000
	k.parent_container = self
	
	ball_ks.append(k)
	sort_ks()
	

func sort_ks():
	ball_ks.sort_custom(func(k1 : BallKeyFrame, k2 : BallKeyFrame):
		return k1.time < k2.time
		)
