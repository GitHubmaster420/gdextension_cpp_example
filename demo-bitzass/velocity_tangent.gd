@tool
class_name VelocityTangent
extends Marker3D

const VEL_MULTIPLIER = 10.0

signal velocity_set(v : float)

@export var velocity : float:
	set(v):
		if v != velocity:
			velocity_set.emit(v)
		velocity = v

@export var pose : Marker3D
@export var tangent : Marker3D

@export var goal_object : Marker3D

@export var super_visible := true

@export var stretcher : Stretcher

@export var tangent_gizmo_controllable : GizmoControllable
@export var velocity_gizmo_controllable : GizmoControllable

func set_goal_object_p_with_vel(vel : float):
	goal_object.position.y = vel / VEL_MULTIPLIER

func _ready() -> void:
	set_goal_object_p_with_vel(velocity)

func _process(delta: float) -> void:
	if not pose or not tangent:
		return
	if not super_visible:
		visible = false
		return
	basis.y = (tangent.basis as Quaternion).get_axis()
	if not global_basis.y:
		visible = false
		global_basis = Basis.IDENTITY
		return
	visible = true
	var temp := Vector3.RIGHT if global_basis.y != Vector3.RIGHT else Vector3.UP
	
	global_basis.z = temp.cross(global_basis.y).normalized()
	
	global_basis.x = global_basis.y.cross(global_basis.z)
	
	if not goal_object:
		return
	if not velocity_gizmo_controllable.gizmo:
		goal_object.position.x = 0
		goal_object.position.z = 0
		goal_object.position.y = velocity
	else:
		velocity = goal_object.position.y * VEL_MULTIPLIER
	if not stretcher:
		return
	(stretcher.mesh as CapsuleMesh).radius = 0.02

func _input(event: InputEvent) -> void:
	if not tangent_gizmo_controllable or not velocity_gizmo_controllable:
		return
	if event is InputEventKey:
		if event.keycode == KEY_R:
			if velocity_gizmo_controllable.gizmo:
				if velocity_gizmo_controllable.gizmo.controllable == velocity_gizmo_controllable:
					velocity_gizmo_controllable.gizmo.controllable = tangent_gizmo_controllable
		if event.keycode == KEY_G:
			if tangent_gizmo_controllable.gizmo:
				if tangent_gizmo_controllable.gizmo.controllable == tangent_gizmo_controllable:
					tangent_gizmo_controllable.gizmo.controllable = velocity_gizmo_controllable
