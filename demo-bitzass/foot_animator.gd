class_name FootAnimator
extends Animator

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

@export var pose_mode := Mode.IK:
	set(v):
		pose_mode = v
		max_current = max_current
@export var tangent_mode := Mode.FK:
	set(v):
		tangent_mode = v
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
		

@export var thigh_pose: Marker3D
@export var shin_pose: Marker3D
@export var foot_pose: Marker3D

@export var thigh_tangent: Marker3D
@export var shin_tangent: Marker3D
@export var foot_tangent: Marker3D




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
		if current > max_current:
			current = 0
		elif current < 0:
			current = max_current
		if not gizmo:
			return
		gizmo.controllable = current_gizmoables[current]
		
		

func _ready() -> void:
	is_right = is_right
	thigh_length = shin_pose.position.length()
	shin_length = foot_pose.position.length()
	edited = edited
	current = current

func select():
	match edited:
		Edited.POSE:
			select_pose()
		Edited.TANGENT:
			select_tangent()

func deselect():
	pose_material.albedo_color.a = 0.1
	tangent_material.albedo_color.a = 0.1

func select_pose():
	pose_material.albedo_color.a = 0.5
	tangent_material.albedo_color.a = 0.25

func select_tangent():
	tangent_material.albedo_color.a = 0.5
	pose_material.albedo_color.a = 0.25


func _process(delta: float) -> void:
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
