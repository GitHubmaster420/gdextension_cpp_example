class_name FootAnimator
extends Animator

@export var thigh_rot_curve : NestedCubicCurve ## works as thigh rot or roll if ik, does nothing if hermite
@export var shin_rot_curve : NestedCubicCurve ## works as shin rot or ik lok if ik, does nothing if hermite
@export var foot_rot_curve : NestedCubicCurve ## works as foot rot fk or ik, does nothing if hermite

signal on_ground_set

enum InterpMode{
	FK_SLERP,
	IK_LERP,
	FK_HERMITE,
	#IK_HERMITE,
	CONSTANT
}

@export var interp_mode : InterpMode = InterpMode.FK_HERMITE:
	set(v):
		interp_mode = v
		interp_mode_changed.emit(interp_mode, self)

@export var is_on_ground := false:
	set(v):
		is_on_ground = v
		if not is_node_ready():
			return
		on_ground_set.emit()
		if is_on_ground:
			pose_mode = Mode.IK

@export var grounded_foot: GroundedFoot

@export var foot_meshes : Array[MeshInstance3D]

@export var is_right := true:
	set(v):
		is_right = v
		if not is_node_ready():
			return
		if not is_right:
			for m in foot_meshes:
				m.basis.x = Vector3.LEFT
		else:
			for m in foot_meshes:
				m.basis.x = Vector3.RIGHT
			

@export var pie_menu : ColorRect

@export var pose_mesh : MeshInstance3D
@export var tangent_mesh : MeshInstance3D

var thigh_length : float

var shin_length : float

var pose_material : StandardMaterial3D:
	get:
		return pose_mesh.get_active_material(0)

var tangent_material : StandardMaterial3D:
	get:
		return tangent_mesh.get_active_material(0)

enum Edited{
	POSE, TANGENT
}

enum Mode{
	FK,
	IK
}

signal pose_mode_set

var selected := false

@export var pose_mode := Mode.IK:
	set(v):
		pose_mode = v
		if not is_node_ready():
			return
		if is_on_ground:
			pose_mode = Mode.IK
		pose_mode_set.emit()
		max_current = max_current
@export var tangent_mode := Mode.FK:
	set(v):
		tangent_mode = v
		if not is_node_ready():
			return
		max_current = max_current

@export var edited := Edited.POSE:
	set(v):
		edited = v
		if not is_node_ready():
			return
		max_current = max_current
		
		match edited:
			Edited.POSE:
				select_pose()
			Edited.TANGENT:
				select_tangent()
		

@export var pelvis: Marker3D

@export var thigh_pose: Marker3D
@export var shin_pose: Marker3D
@export var foot_pose: Marker3D

@export var thigh_tangent: Marker3D
@export var shin_tangent: Marker3D
@export var foot_tangent: Marker3D


@export var thigh_tangent_prev_angle_menu: AngleMenu
@export var thigh_tangent_next_angle_menu: AngleMenu
@export var shin_tangent_prev_angle_menu: AngleMenu
@export var shin_tangent_next_angle_menu: AngleMenu
@export var foot_tangent_prev_angle_menu: AngleMenu
@export var foot_tangent_next_angle_menu: AngleMenu

@export var thigh_tangent_prev_influence : float
@export var thigh_tangent_next_influence : float
@export var shin_tangent_prev_influence : float
@export var shin_tangent_next_influence : float
@export var foot_tangent_prev_influence : float
@export var foot_tangent_next_influence : float

@export var thigh_angular_velocity_setter: LineEdit
@export var shin_angular_velocity_setter: LineEdit
@export var foot_angular_velocity_setter: LineEdit

@export var thigh_angular_velocity : float ##rad/s
@export var shin_angular_velocity : float ##rad/s
@export var foot_angular_velocity : float ##rad/s

@export var pose_fk_gizmoables : Array[GizmoControllable]
@export var tangent_fk_gizmoables : Array[GizmoControllable]

@export var pose_mode_ik_gizmoables : Array[GizmoControllable]
@export var tangent_mode_ik_gizmoables : Array[GizmoControllable]

var current_gizmoables : Array[GizmoControllable]

@export var foot_ik_pose: Marker3D
@export var foot_ik_tangent: Marker3D

@export var foot_ik_pose_roll: Marker3D
@export var foot_ik_tangent_roll: Marker3D

var max_current := 1:
	set(v):
		if not is_node_ready():
			return
		match edited:
			Edited.POSE:
				match pose_mode:
					Mode.IK:
						max_current = 1
						current_gizmoables = pose_mode_ik_gizmoables
					Mode.FK:
						max_current = 2
						current_gizmoables = pose_fk_gizmoables
			Edited.TANGENT:
				match tangent_mode:
					Mode.IK:
						max_current = 1
						current_gizmoables = tangent_mode_ik_gizmoables
					Mode.FK:
						max_current = 2
						current_gizmoables = tangent_fk_gizmoables
		current = current
		if not gizmo:
			return
		
		

var current := 0:
	set(v):
		current = v
		if not is_node_ready():
			return
		hide_stuff()
		
		if current > max_current:
			current = 0
		elif current < 0:
			current = max_current
		if not gizmo:
			return
		
		if is_on_ground:
			if current == 0:
				gizmo.controllable = pose_mode_ik_gizmoables[0]
				grounded_foot.gizmo = null
			else:
				grounded_foot.gizmo = gizmo
		else:
			grounded_foot.gizmo = null
			gizmo.controllable = current_gizmoables[current]
		show_rotations()

func on_gizmo_set(_gizmo : Gizmo):
	if _gizmo:
		current = current
		if not _gizmo.mode_set.is_connected(on_gizmo_mode_set):
			_gizmo.mode_set.connect(on_gizmo_mode_set)
		if not _gizmo.pressed.is_connected(on_gizmo_pressed):
			_gizmo.pressed.connect(on_gizmo_pressed.bind(_gizmo))
		if not _gizmo.released.is_connected(on_gizmo_released):
			_gizmo.released.connect(on_gizmo_released.bind(_gizmo))
			print("connected gizmo released")

func on_gizmo_pressed(_gizmo : Gizmo):
	if not _gizmo or not gizmo:
		return

func on_gizmo_released(_gizmo : Gizmo):
	print("gizmo released")
	if not _gizmo or not gizmo:
		return
	print("!!!")
	thigh_tangent_next_angle_menu.default_angle = rad_to_deg(Quaternion.from_euler(thigh_tangent.global_rotation).angle_to(Quaternion.from_euler(thigh_pose.global_rotation)))
	thigh_tangent_prev_angle_menu.default_angle = rad_to_deg(Quaternion.from_euler(thigh_tangent.global_rotation).angle_to(Quaternion.from_euler(thigh_pose.global_rotation)))
	shin_tangent_next_angle_menu.default_angle = rad_to_deg(Quaternion.from_euler(shin_tangent.global_rotation).angle_to(Quaternion.from_euler(shin_pose.global_rotation)))
	shin_tangent_prev_angle_menu.default_angle = rad_to_deg(Quaternion.from_euler(shin_tangent.global_rotation).angle_to(Quaternion.from_euler(shin_pose.global_rotation)))
	foot_tangent_next_angle_menu.default_angle = rad_to_deg(Quaternion.from_euler(foot_tangent.global_rotation).angle_to(Quaternion.from_euler(foot_pose.global_rotation)))
	foot_tangent_prev_angle_menu.default_angle = rad_to_deg(Quaternion.from_euler(foot_tangent.global_rotation).angle_to(Quaternion.from_euler(foot_pose.global_rotation)))
	

func on_gizmo_mode_set(mode : Gizmo.Mode):
	hide_stuff()
	show_rotations()


func show_rotations():
	if not selected:
		return
	if edited == Edited.TANGENT:
		
		if tangent_mode == Mode.FK:
			match current:
				0:
					
					if is_prev_keyframe:
						thigh_angular_velocity_setter.visible = true
						thigh_tangent_next_angle_menu.visible = true
					elif is_next_keyframe:
						thigh_angular_velocity_setter.visible = true
						thigh_tangent_prev_angle_menu.visible = true
				1:
					
					if is_prev_keyframe:
						shin_tangent_next_angle_menu.visible = true
						shin_angular_velocity_setter.visible = true
					elif is_next_keyframe:
						shin_tangent_prev_angle_menu.visible = true
						shin_angular_velocity_setter.visible = true
				2:
					
					if is_prev_keyframe:
						foot_tangent_next_angle_menu.visible = true
						foot_angular_velocity_setter.visible = true
					elif is_next_keyframe:
						foot_tangent_prev_angle_menu.visible = true
						foot_angular_velocity_setter.visible = true
		else:
			if current == 0:
				if is_prev_keyframe:
					thigh_angular_velocity_setter.visible = true
					thigh_tangent_next_angle_menu.visible = true
				elif is_next_keyframe:
					thigh_angular_velocity_setter.visible = true
					thigh_tangent_prev_angle_menu.visible = true
			else:
				if gizmo.mode == Gizmo.Mode.GRAB:
					if is_prev_keyframe:
						foot_tangent_next_angle_menu.visible = true
						foot_angular_velocity_setter.visible = true
					elif is_next_keyframe:
						foot_tangent_prev_angle_menu.visible = true
						foot_angular_velocity_setter.visible = true
				else:
					if is_prev_keyframe:
						shin_tangent_next_angle_menu.visible = true
						shin_angular_velocity_setter.visible = true
					elif is_next_keyframe:
						shin_tangent_prev_angle_menu.visible = true
						shin_angular_velocity_setter.visible = true

func _ready() -> void:
	is_right = is_right
	thigh_length = shin_pose.position.length()
	shin_length = foot_pose.position.length()
	edited = edited
	current = current
	is_on_ground = is_on_ground
	gizmo_set.connect(on_gizmo_set)
	gizmo = gizmo
	thigh_tangent_next_angle_menu.angle_set.connect(func():
		thigh_tangent_next_influence = (thigh_tangent_next_angle_menu.angle)/180.0)
	thigh_tangent_prev_angle_menu.angle_set.connect(func():
		thigh_tangent_prev_influence = (thigh_tangent_prev_angle_menu.angle)/180.0)
	shin_tangent_next_angle_menu.angle_set.connect(func():
		shin_tangent_next_influence = (shin_tangent_next_angle_menu.angle)/180.0)
	shin_tangent_prev_angle_menu.angle_set.connect(func():
		shin_tangent_prev_influence = (shin_tangent_prev_angle_menu.angle)/180.0)
	foot_tangent_next_angle_menu.angle_set.connect(func():
		foot_tangent_next_influence = (foot_tangent_next_angle_menu.angle)/180.0)
	foot_tangent_prev_angle_menu.angle_set.connect(func():
		foot_tangent_prev_influence = (foot_tangent_prev_angle_menu.angle) / 180.0)
	
	thigh_angular_velocity = deg_to_rad(float(thigh_angular_velocity_setter.text))
	shin_angular_velocity = deg_to_rad(float(shin_angular_velocity_setter.text))
	foot_angular_velocity = deg_to_rad(float(foot_angular_velocity_setter.text))
	
	thigh_tangent_next_angle_menu.angle_set.emit()
	thigh_tangent_prev_angle_menu.angle_set.emit()
	shin_tangent_next_angle_menu.angle_set.emit()
	shin_tangent_prev_angle_menu.angle_set.emit()
	foot_tangent_next_angle_menu.angle_set.emit()
	foot_tangent_prev_angle_menu.angle_set.emit()
	
	
	
	thigh_angular_velocity_setter.text_submitted.connect(func(text : String):
		thigh_angular_velocity = deg_to_rad(float(text))
		)
	shin_angular_velocity_setter.text_submitted.connect(func(text : String):
		shin_angular_velocity = deg_to_rad(float(text))
		)
	foot_angular_velocity_setter.text_submitted.connect(func(text : String):
		foot_angular_velocity = deg_to_rad(float(text))
		)
	visibility_changed.connect(func():
		if not visible:
			hide_stuff()
			return
		if not gizmo:
			return
		gizmo.mode = gizmo.mode
		)
	set_prev_keyframe.connect(func():
		hide_stuff()
		show_rotations())
	set_next_keyframe.connect(func():
		hide_stuff()
		show_rotations())

func hide_stuff():
	for ci : CanvasItem in [thigh_angular_velocity_setter, 
		thigh_tangent_next_angle_menu, 
		thigh_tangent_prev_angle_menu,
		shin_angular_velocity_setter,
		shin_tangent_next_angle_menu,
		shin_tangent_prev_angle_menu,
		foot_angular_velocity_setter, 
		foot_tangent_next_angle_menu, 
		foot_tangent_prev_angle_menu
		]:
		ci.visible = false

func select():
	selected = true
	match edited:
		Edited.POSE:
			select_pose()
		Edited.TANGENT:
			select_tangent()
	hide_stuff()
	show_rotations()

func deselect():
	selected = false
	hide_stuff()
	pose_material.albedo_color.a = 0.1
	tangent_material.albedo_color.a = 0.1

func select_pose():
	pose_material.albedo_color.a = 0.5
	tangent_material.albedo_color.a = 0.25

func select_tangent():
	tangent_material.albedo_color.a = 0.5
	pose_material.albedo_color.a = 0.25


func _process(delta: float) -> void:
	if is_on_ground:
		foot_ik_pose.global_transform = grounded_foot.ankle.global_transform
	if pose_mode == Mode.IK:
		var rots := IkInterpstatic.get_ik_interpolation(thigh_pose.global_position, foot_ik_pose.global_position, thigh_length, shin_length, foot_ik_pose_roll.rotation.y)
		thigh_pose.global_rotation = rots[0].get_euler()
		shin_pose.rotation = rots[1].get_euler()
		foot_pose.global_rotation = foot_ik_pose.global_rotation
	else:
		foot_ik_pose.global_transform = foot_pose.global_transform
		foot_ik_pose_roll.global_transform = thigh_pose.global_transform
	if tangent_mode == Mode.IK:
		var rots := IkInterpstatic.get_ik_interpolation(thigh_tangent.global_position, foot_ik_tangent.global_position, thigh_length, shin_length, foot_ik_tangent_roll.rotation.y)
		thigh_tangent.global_rotation = rots[0].get_euler()
		shin_tangent.rotation = rots[1].get_euler()
		foot_tangent.global_rotation = foot_ik_tangent.global_rotation
	else:
		foot_ik_tangent.global_transform = foot_tangent.global_transform
		foot_ik_tangent_roll.global_transform = thigh_tangent.global_transform

func _input(event: InputEvent) -> void:
	if not gizmo or not visible:
		return
	if event is InputEventKey:
		if not event.pressed:
			return
		if event.keycode == KEY_D:
			current += 1
		if event.keycode == KEY_A:
			current -= 1
		if event.keycode == KEY_S:
			edited = Edited.POSE if edited != Edited.POSE else Edited.TANGENT

func right_clicked_empty(pressed : bool):
	if not gizmo:
		if not pressed:
			pie_menu.visible = false #in case of bugs
		return
	pie_menu.visible = pressed
