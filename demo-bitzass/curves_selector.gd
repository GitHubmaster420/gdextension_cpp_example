extends ColorRect

const HOVERED_COLOR := Color(0.43, 0.43, 0.43, 1.0)
const UNHOVERED_COLOR := Color(1.0, 1.0, 1.0, 1.0)

@export var name_label : Label

@export var anim_tack_holder: AnimTrackHolder

@export var track_names : Array[Label]

@export var bezier_editor_scene : PackedScene

@export var keyframe_curves : Dictionary[Keyframe, Array]

@export var circle_shader : ShaderMaterial

var hovered := false:
	set(v):
		hovered = v
		var stored_a := color.a
		color = HOVERED_COLOR if hovered else UNHOVERED_COLOR
		color.a = stored_a

var selected := false:
	set(v):
		if track_names.size() <= 0 or anim_tack_holder.keyframes.size() <= 1:
			selected = false
			return
		position.y = 50
		selected = v
		if selected:
			color.a = 0
			name_label.visible = false
			size.x = anim_tack_holder.size.x
			position.x = 0
			var total_size_y := track_names.size() * 100.0

			
			var keys : Array[Keyframe]
			keys.assign(keyframe_curves.keys())
			
			keys.sort_custom(func(a : Keyframe, b : Keyframe):
				return a.time < b.time
				)
			var prev_y := 0.0
			for i in range(track_names.size()):
				var top := float(i) / float(track_names.size())
				var bottom := float(i + 1) / float(track_names.size())
				for j in range(0, keys.size() - 1, 1):
					var prev_pos := keys[j].position.x
					var next_pos := keys[j + 1].position.x
					var r := keyframe_curves[keys[j]][i] as ColorRect
					r.anchor_top = top + 0.01
					r.anchor_bottom = bottom - 0.01
					r.size.y = 100
					r.position.y = prev_y
					
					r.size.x = next_pos - prev_pos - 2
					r.position.x = prev_pos
					r.visible = true
					print("r top: ", r.anchor_top, " r bottom: ", r.anchor_bottom)
				prev_y += 100

			size.y = total_size_y
		else:
			color.a = 1

func on_bez_selected(is_selected : bool, bez : ClampedBezierEditor):
	if not is_selected:
		selected = selected
		return
	size.y = 300
	position.y = 200
	#for n in curves:
		#if curves[n] == bez:
			#curves[n].anchor_top = 0
			#curves[n].anchor_bottom = 1.0
			#track_names[n].position.y = 0
			#continue
		#curves[n].visible = false
		#track_names[n].visible = false

func on_animator_interp_mode_changed(interp_mode, animator : Animator):
	if animator is FootAnimator:
		pass

func on_curve_added():
	var bez_editor := bezier_editor_scene.instantiate() as ClampedBezierEditor
	add_child(bez_editor)
	(bez_editor as CanvasItem).visible = false
	bez_editor.selected_set.connect(on_bez_selected.bind(bez_editor))

func on_keyframe_added(kf : Keyframe):
	if kf.animator is FootAnimator:
		keyframe_curves[kf] = []
		var j := 0
		for track in track_names:
			var new_rect := bezier_editor_scene.instantiate() as ClampedBezierEditor
			var _color := new_rect.color
			_color.s = 0.5
			_color.h = float(j) / track_names.size()
			new_rect.color = _color
			j += 1
			new_rect.color.a = 0.1
			new_rect.selected_set.connect((func(is_selected : bool, editor : ClampedBezierEditor):
				if is_selected:
					size.x = anim_tack_holder.size.x
					for i in range(track_names.size()):
						for k in keyframe_curves:
							
							for c : ClampedBezierEditor in keyframe_curves[k]:
								if c == editor:
									c.size = size
									c.position = Vector2.ONE
									c.anchor_top = 0.0
									c.anchor_bottom = 1.0
									c.anchor_left = 0.0
									c.anchor_right = 1.0
									
									continue
								c.visible = false
				else:
					selected = selected
					).bind(new_rect)
				)
			add_child(new_rect)
			

			
			keyframe_curves[kf].append(new_rect)
			new_rect.visible = false
		selected = selected
		
		
		return
		

func _ready() -> void:
	mouse_entered.connect(func(): hovered = true)
	mouse_exited.connect(func(): hovered = false)
	for t in track_names:
		t.visible = false
	anim_tack_holder.keyframe_added.connect(on_keyframe_added)
	


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			selected = true
			
