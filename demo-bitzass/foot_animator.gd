class_name FootAnimator
extends Animator

@export var left_side: Control
@export var right_control: Control


@export var thigh_rot_curve : MyEaseInOut: ## works as thigh rot or roll if ik
	set(v):
		thigh_rot_curve = v
		thigh_rot_curve.bake_fast()
		if not is_node_ready():
			return
		thigh_ease_curve_drawer.my_ease_in_out_curve = thigh_rot_curve
@export var shin_rot_curve : MyEaseInOut: ## works as shin rot or ik loc if ik
	set(v):
		shin_rot_curve = v
		shin_rot_curve.bake_fast()
		if not is_node_ready():
			return
		shin_ease_curve_drawer.my_ease_in_out_curve = shin_rot_curve
		
@export var foot_rot_curve : MyEaseInOut: ## works as foot rot fk or ik
	set(v):
		foot_rot_curve = v
		foot_rot_curve.bake_fast()
		if not is_node_ready():
			return
		foot_ease_curve_drawer.my_ease_in_out_curve = foot_rot_curve

@export var shin_start_ease: EaseDrawer
@export var shin_end_ease: EaseDrawer
@export var foot_start_ease: EaseDrawer
@export var foot_end_ease: EaseDrawer
@export var thigh_start_ease: EaseDrawer
@export var thigh_end_ease: EaseDrawer


signal on_ground_set

enum InterpMode{
	FK_HERMITE,
	IK_HERMITE,
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

@export var thigh_stretcher: Stretcher
@export var shin_stetcher: Stretcher
@export var foot_pose_mesh: MeshInstance3D


@export var thigh_tangent_mesh: MeshInstance3D
@export var shin_tangent_mesh: MeshInstance3D
@export var foot_tangent_mesh: MeshInstance3D


var thigh_length : float

var shin_length : float

#var pose_material : StandardMaterial3D:
	#get:
		#return pose_mesh.get_active_material(0)


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
#
#
#@export var thigh_tangent_prev_angle_menu: AngleMenu
#@export var thigh_tangent_next_angle_menu: AngleMenu
#@export var shin_tangent_prev_angle_menu: AngleMenu
#@export var shin_tangent_next_angle_menu: AngleMenu
#@export var foot_tangent_prev_angle_menu: AngleMenu
#@export var foot_tangent_next_angle_menu: AngleMenu

@export var shin_ease_curve_drawer: EaseCurveDrawer
@export var shin_h_slider: HSlider
@export var shin_v_slider: VSlider
@export var shin_v_slider_2: VSlider
@export var foot_ease_curve_drawer: EaseCurveDrawer
@export var foot_h_slider: HSlider
@export var foot_v_slider: VSlider
@export var foot_v_slider_2: VSlider
@export var thigh_ease_curve_drawer: EaseCurveDrawer
@export var thigh_h_slider: HSlider
@export var thigh_v_slider: VSlider
@export var thigh_v_slider_2: VSlider


@export var thigh_tangent_prev_influence : float
@export var thigh_tangent_next_influence : float
@export var shin_tangent_prev_influence : float
@export var shin_tangent_next_influence : float
@export var foot_tangent_prev_influence : float
@export var foot_tangent_next_influence : float

#@export var thigh_angular_velocity_setter: LineEdit
#@export var shin_angular_velocity_setter: LineEdit
#@export var foot_angular_velocity_setter: LineEdit

@export var thigh_velocity_tangent: VelocityTangent
@export var shin_velocity_tangent: VelocityTangent
@export var foot_velocity_tangent: VelocityTangent


@export var thigh_angular_velocity : float: ##rad/s
	set(v):
		thigh_angular_velocity = v
		if not is_node_ready():
			return
@export var shin_angular_velocity : float: ##rad/s
	set(v):
		shin_angular_velocity = v
@export var foot_angular_velocity : float: ##rad/s
	set(v):
		foot_angular_velocity = v

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
		#hide_stuff()
		
		if current > max_current:
			current = 0
		elif current < 0:
			current = max_current
		if not gizmo:
			return
		var meshes : Array[MeshInstance3D ]= [
		thigh_stretcher, shin_stetcher, foot_pose_mesh,
		thigh_tangent_mesh, shin_tangent_mesh, foot_tangent_mesh
		]
		for m in meshes:
			(m.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
		match edited:
			Edited.POSE:
				if pose_mode == Mode.FK:
					(meshes[current].get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5
				else:
					if current == 1:
						(foot_pose_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5
					else:
						(thigh_stretcher.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5
						(shin_stetcher.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5
			Edited.TANGENT:
				if tangent_mode == Mode.FK:
					(meshes[current + 3].get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5
				#else:
					#if current == 1:
						#if gizmo.mode == Gizmo.Mode.GRAB:
							#(shin_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5
						#else:
							#(foot_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5
					#else:
						#(thigh_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5
		if is_on_ground:
			if current == 0:
				gizmo.controllable = pose_mode_ik_gizmoables[0]
				grounded_foot.gizmo = null
			else:
				grounded_foot.gizmo = gizmo
		else:
			grounded_foot.gizmo = null
			gizmo.controllable = current_gizmoables[current]
		#show_rotations()

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
	if is_on_ground:
		grounded_foot.on_gizmo_released()
	print("!!!")
	#thigh_tangent_next_angle_menu.default_angle = rad_to_deg(Quaternion.from_euler(thigh_tangent.global_rotation).angle_to(Quaternion.from_euler(thigh_pose.global_rotation)))
	#thigh_tangent_prev_angle_menu.default_angle = rad_to_deg(Quaternion.from_euler(thigh_tangent.global_rotation).angle_to(Quaternion.from_euler(thigh_pose.global_rotation)))
	#shin_tangent_next_angle_menu.default_angle = rad_to_deg(Quaternion.from_euler(shin_tangent.global_rotation).angle_to(Quaternion.from_euler(shin_pose.global_rotation)))
	#shin_tangent_prev_angle_menu.default_angle = rad_to_deg(Quaternion.from_euler(shin_tangent.global_rotation).angle_to(Quaternion.from_euler(shin_pose.global_rotation)))
	#foot_tangent_next_angle_menu.default_angle = rad_to_deg(Quaternion.from_euler(foot_tangent.global_rotation).angle_to(Quaternion.from_euler(foot_pose.global_rotation)))
	#foot_tangent_prev_angle_menu.default_angle = rad_to_deg(Quaternion.from_euler(foot_tangent.global_rotation).angle_to(Quaternion.from_euler(foot_pose.global_rotation)))
	

func on_gizmo_mode_set(mode : Gizmo.Mode):
	return
	#hide_stuff()
#



func _ready() -> void:
	is_right = is_right
	thigh_length = shin_pose.position.length()
	shin_length = foot_pose.position.length()
	edited = edited
	current = current
	is_on_ground = is_on_ground
	gizmo_set.connect(on_gizmo_set)
	gizmo = gizmo
	
	thigh_rot_curve = thigh_rot_curve
	shin_rot_curve = shin_rot_curve
	foot_rot_curve = foot_rot_curve
	
	thigh_start_ease.value_changed.connect(func(v : float):
		thigh_tangent_prev_influence = v
		)
	thigh_end_ease.value_changed.connect(func(v : float):
		thigh_tangent_next_influence = v
		)
	shin_start_ease.value_changed.connect(func(v : float):
		shin_tangent_prev_influence = v
		)
	shin_end_ease.value_changed.connect(func(v : float):
		shin_tangent_next_influence = v
		)
	foot_start_ease.value_changed.connect(func(v : float):
		foot_tangent_prev_influence = v
		)
	foot_start_ease.value_changed.connect(func(v : float):
		foot_tangent_next_influence = v
		)
	
	thigh_tangent_prev_influence = thigh_start_ease.ease_amount
	thigh_tangent_next_influence = thigh_end_ease.ease_amount
	shin_tangent_prev_influence = shin_start_ease.ease_amount
	shin_tangent_next_influence = shin_end_ease.ease_amount
	foot_tangent_prev_influence = foot_start_ease.ease_amount
	foot_tangent_next_influence = foot_end_ease.ease_amount
	
	
	#thigh_tangent_next_angle_menu.angle_set.connect(func():
		#thigh_tangent_next_influence = (thigh_tangent_next_angle_menu.angle)/180.0)
	#thigh_tangent_prev_angle_menu.angle_set.connect(func():
		#thigh_tangent_prev_influence = (thigh_tangent_prev_angle_menu.angle)/180.0)
	#shin_tangent_next_angle_menu.angle_set.connect(func():
		#shin_tangent_next_influence = (shin_tangent_next_angle_menu.angle)/180.0)
	#shin_tangent_prev_angle_menu.angle_set.connect(func():
		#shin_tangent_prev_influence = (shin_tangent_prev_angle_menu.angle)/180.0)
	#foot_tangent_next_angle_menu.angle_set.connect(func():
		#foot_tangent_next_influence = (foot_tangent_next_angle_menu.angle)/180.0)
	#foot_tangent_prev_angle_menu.angle_set.connect(func():
		#foot_tangent_prev_influence = (foot_tangent_prev_angle_menu.angle) / 180.0)
	#
	#thigh_angular_velocity = deg_to_rad(float(thigh_angular_velocity_setter.text))
	#shin_angular_velocity = deg_to_rad(float(shin_angular_velocity_setter.text))
	#foot_angular_velocity = deg_to_rad(float(foot_angular_velocity_setter.text))
	
	thigh_velocity_tangent.velocity = thigh_angular_velocity
	thigh_velocity_tangent.set_goal_object_p_with_vel(thigh_angular_velocity)
	thigh_velocity_tangent.velocity_set.connect(func(v : float):
		thigh_angular_velocity = v
		)
	
	shin_velocity_tangent.velocity = shin_angular_velocity
	shin_velocity_tangent.set_goal_object_p_with_vel(shin_angular_velocity)
	shin_velocity_tangent.velocity_set.connect(func(v : float):
		shin_angular_velocity = v
		)
	
	foot_velocity_tangent.velocity = foot_angular_velocity
	foot_velocity_tangent.set_goal_object_p_with_vel(foot_angular_velocity)
	foot_velocity_tangent.velocity_set.connect(func(v : float):
		foot_angular_velocity = v
		)
	
	
	
	#thigh_tangent_next_angle_menu.angle_set.emit()
	#thigh_tangent_prev_angle_menu.angle_set.emit()
	#shin_tangent_next_angle_menu.angle_set.emit()
	#shin_tangent_prev_angle_menu.angle_set.emit()
	#foot_tangent_next_angle_menu.angle_set.emit()
	#foot_tangent_prev_angle_menu.angle_set.emit()
	#
	#
	#
	#thigh_angular_velocity_setter.text_submitted.connect(func(text : String):
		#thigh_angular_velocity = deg_to_rad(float(text))
		#)
	#shin_angular_velocity_setter.text_submitted.connect(func(text : String):
		#shin_angular_velocity = deg_to_rad(float(text))
		#)
	#foot_angular_velocity_setter.text_submitted.connect(func(text : String):
		#foot_angular_velocity = deg_to_rad(float(text))
		#)
	
	visibility_changed.connect(func():
		if not is_visible_in_tree():
			#hide_stuff()
			right_control.hide()
			left_side.hide()
			return
		if not gizmo:
			return
		gizmo.mode = gizmo.mode
		)
	#set_prev_keyframe.connect(func():
		#hide_stuff()
		#show_rotations())
	#set_next_keyframe.connect(func():
		#hide_stuff()
		#show_rotations())
#
#func hide_stuff():
	#for ci : CanvasItem in [thigh_angular_velocity_setter, 
		#thigh_tangent_next_angle_menu, 
		#thigh_tangent_prev_angle_menu,
		#shin_angular_velocity_setter,
		#shin_tangent_next_angle_menu,
		#shin_tangent_prev_angle_menu,
		#foot_angular_velocity_setter, 
		#foot_tangent_next_angle_menu, 
		#foot_tangent_prev_angle_menu
		#]:
		#ci.visible = false

func select():
	selected = true
	right_control.show()
	left_side.show()
	match edited:
		Edited.POSE:
			select_pose()
		Edited.TANGENT:
			select_tangent()
	#hide_stuff()
	#show_rotations()

func deselect():
	selected = false
	#hide_stuff()
	var meshes : Array[MeshInstance3D ]= [
		thigh_stretcher, shin_stetcher, foot_pose_mesh,
		thigh_tangent_mesh, shin_tangent_mesh, foot_tangent_mesh
	]
	for m in meshes:
		(m.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
	#pose_material.albedo_color.a = 0.1
	#tangent_material.albedo_color.a = 0.1
	right_control.hide()
	left_side.hide()

func select_pose():
	pass
	#pose_material.albedo_color.a = 0.5
	#tangent_material.albedo_color.a = 0.25

func select_tangent():
	pass
	#tangent_material.albedo_color.a = 0.5
	#pose_material.albedo_color.a = 0.25


func _process(delta: float) -> void:
	if is_on_ground:
		foot_ik_pose.global_transform = grounded_foot.ankle.global_transform
	else:
		grounded_foot.follow_foot(foot_ik_pose.global_transform)
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
