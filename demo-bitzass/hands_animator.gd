extends Animator
class_name HandsAnimator

@export var thigh_auto_vel_check_button: CheckButton

@export var side_panel: Control

signal request_auto_velocity(idx : int)

@export var hand_mesh: MeshInstance3D
@export var low_arm_stretcher: Stretcher
@export var up_arm_stretcher: Stretcher

@export var up_arm_tangent_mesh: MeshInstance3D
@export var low_arm_tangent_mesh: MeshInstance3D
@export var hand_tangent_mesh: MeshInstance3D


var current := 0:
	set(v):
		current = v
		if current > max_current:
			current = 0
		elif current < 0:
			current = max_current
		var meshes : Array[MeshInstance3D] = [up_arm_stretcher, low_arm_stretcher, hand_mesh, up_arm_tangent_mesh, low_arm_tangent_mesh, hand_tangent_mesh]
		for m in meshes:
			(m.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
		if not gizmo:
			return
		var current_gimoables : Array[GizmoControllable]
		var m_idx : int
		match edited:
			Edited.POSE:
				current_gimoables = pose_fk_gizmoables
				m_idx = current
			Edited.TANGENT:
				current_gimoables = tangent_fk_gizmoables
				m_idx = 3 + current
			_:
				assert(false)
		if selected:
			(meshes[m_idx].get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5
		gizmo.controllable = current_gimoables[current]
		current_gimoables[current].gizmo = gizmo

var max_current := 2:
	set(v):
		match edited:
			Edited.POSE:
				match pose_mode:
					Mode.FK:
						max_current = 2
					Mode.IK:
						max_current = 1
			Edited.TANGENT:
				max_current = 2
		
		current = current

enum Edited{
	POSE,
	TANGENT
}

@export var edited := Edited.POSE:
	set(v):
		edited = v
		max_current = max_current

enum Mode{
	FK,
	IK
}

@export var pose_mode := Mode.FK

@export var pose_fk_gizmoables : Array[GizmoControllable]

@export var tangent_fk_gizmoables : Array[GizmoControllable]

@export var pose_mesh_instance : MeshInstance3D

@export var up_arm_pose: Marker3D
@export var low_arm_pose: Marker3D
@export var hand_pose: Marker3D

@export var up_arm_tangent_object : Marker3D
@export var low_arm_tangent_object : Marker3D
@export var hand_tangent_object : Marker3D

@export var up_arm_velocity_tangent_object : VelocityTangent
@export var low_arm_velocity_tangent_object : VelocityTangent
@export var hand_velocity_tangent_object : VelocityTangent

@export var chest: Marker3D

@export var shoulder_pose: Marker3D

@export var up_arm_tangent : Vector3
@export var low_arm_tangent : Vector3
@export var hand_tangent : Vector3

@export var use_up_arm_auto_tangent := true
@export var use_low_arm_auto_tangent := true
@export var use_hand_auto_tagent := true

@export var up_arm_ease_curve : MyEaseInOut
@export var low_arm_ease_curve : MyEaseInOut
@export var hand_ease_curve : MyEaseInOut

@export_range(-1.0, 1.0, 0.01) var up_arm_auto_influence := 0.0
@export_range(-1.0, 1.0, 0.01) var low_arm_auto_influence := 0.0
@export_range(-1.0, 1.0, 0.01) var hand_auto_influence := 0.0

@export var up_arm_angular_velocity : float
@export var low_arm_angular_velocity : float
@export var hand_angular_velocity : float

var selected := false

func _ready() -> void:
	current = current
	#(pose_mesh_instance.get_active_material(0) as StandardMaterial3D).albedo_color.r = randf()
	#(pose_mesh_instance.get_active_material(0) as StandardMaterial3D).albedo_color.g = randf()
	#(pose_mesh_instance.get_active_material(0) as StandardMaterial3D).albedo_color.b = randf()
	edited = Edited.POSE
	gizmo_set.connect(on_gizmo_set)
	hand_velocity_tangent_object.velocity_set.connect(func(v : float):
		hand_angular_velocity = v)
	low_arm_velocity_tangent_object.velocity_set.connect(func(v : float):
		low_arm_angular_velocity = v
		)
	up_arm_velocity_tangent_object.velocity_set.connect(func(v : float):
		up_arm_angular_velocity = v
		)
	thigh_auto_vel_check_button.button_pressed = use_up_arm_auto_tangent
	thigh_auto_vel_check_button.toggled.connect(func(b:  bool):
		use_up_arm_auto_tangent = b
		)

func on_gizmo_set(_g : Gizmo):
	edited = Edited.POSE

func select():
	visible = true
	selected = true
	edited = edited
	side_panel.visible = true
	for v : VelocityTangent in [up_arm_velocity_tangent_object, low_arm_velocity_tangent_object, hand_velocity_tangent_object]:
		v.super_visible = true

func deselect():
	selected = false
	edited = edited
	side_panel.visible = false
	for v : VelocityTangent in [up_arm_velocity_tangent_object, low_arm_velocity_tangent_object, hand_velocity_tangent_object]:
		v.super_visible = false

func right_clicked_empty(is_clicked : bool):
	pass

func _process(delta: float) -> void:
	if not use_up_arm_auto_tangent:
		up_arm_tangent = (up_arm_tangent_object.basis as Quaternion).get_axis()
	else:
		if up_arm_tangent:
			up_arm_tangent_object.basis = Quaternion(up_arm_tangent, up_arm_angular_velocity)
	if not use_low_arm_auto_tangent:
		low_arm_tangent = (low_arm_tangent_object.basis as Quaternion).get_axis()
	else:
		if low_arm_tangent:
			low_arm_tangent_object.basis = Quaternion(low_arm_tangent, low_arm_angular_velocity)
	if not use_hand_auto_tagent:
		hand_tangent = (hand_tangent_object.basis as Quaternion).get_axis()
	else:
		if hand_tangent:
			hand_tangent_object.basis = Quaternion(hand_tangent, hand_angular_velocity)

func set_aut_velocity(idx : int, v : float):
	match idx:
		0:
			up_arm_angular_velocity = v
			up_arm_velocity_tangent_object.set_goal_object_p_with_vel(v)
		1:
			low_arm_angular_velocity = v
			low_arm_velocity_tangent_object.set_goal_object_p_with_vel(v)
		2:
			hand_angular_velocity = v
			hand_velocity_tangent_object.set_goal_object_p_with_vel(v)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.pressed:
			return
		if event.keycode == KEY_D:
			current += 1
		if event.keycode == KEY_A:
			current -= 1
		if event.keycode == KEY_V and event.alt_pressed:
			if not selected:
				return
			request_auto_velocity.emit(current)
		if event.keycode == KEY_S:
			if edited == Edited.POSE:
				edited = Edited.TANGENT
			else:
				edited = Edited.POSE
