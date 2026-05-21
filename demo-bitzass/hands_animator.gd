extends Animator
class_name HandsAnimator


var current := 0:
	set(v):
		current = v
		if current > max_current:
			current = 0
		elif current < 0:
			current = max_current
		if not gizmo:
			return
		gizmo.controllable = pose_fk_gizmoables[current]

var max_current := 2:
	set(v):
		match edited:
			Edited.POSE:
				match pose_mode:
					Mode.FK:
						max_current = 2
					Mode.IK:
						max_current = 1
		
		current = current

enum Edited{
	POSE
}

@export var edited := Edited.POSE

enum Mode{
	FK,
	IK
}

@export var pose_mode := Mode.FK

@export var pose_fk_gizmoables : Array[GizmoControllable]

@export var pose_mesh_instance : MeshInstance3D

@export var up_arm_pose: Marker3D
@export var low_arm_pose: Marker3D
@export var hand_pose: Marker3D

@export var chest: Marker3D

@export var shoulder_pose: Marker3D


func _ready() -> void:
	current = current
	(pose_mesh_instance.get_active_material(0) as StandardMaterial3D).albedo_color.r = randf()
	(pose_mesh_instance.get_active_material(0) as StandardMaterial3D).albedo_color.g = randf()
	(pose_mesh_instance.get_active_material(0) as StandardMaterial3D).albedo_color.b = randf()

func select():
	visible = true
	(pose_mesh_instance.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5

func deselect():
	(pose_mesh_instance.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1

func right_clicked_empty(is_clicked : bool):
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.pressed:
			return
		if event.keycode == KEY_D:
			current += 1
		if event.keycode == KEY_A:
			current -= 1
