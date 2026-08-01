extends Animator
class_name RootAnimator

var current := 0

@export var gizmo_controllable: GizmoControllable
@export var tangent_gizmo_controllable : GizmoControllable

@export var root: Marker3D
@export var root_tangent: Marker3D
@export var velocity_tangent: VelocityTangent
@export var vel_object: Marker3D

@export var angular_velocity_tangent : Vector3
@export var angular_velocity_amount : float

@export var velocity_tangent_vector : Vector3

@export var rot_ease_curve : MyEaseInOut
@export var loc_ease_curve : MyEaseInOut

@export var tangent_mesh: MeshInstance3D
@export var root_mesh: MeshInstance3D


enum Mode{
	POSE,
	TANGENT
}

@export var mode := Mode.POSE:
	set(v):
		mode = v
		if not gizmo:
			return
		match mode:
			Mode.POSE:
				gizmo.controllable = gizmo_controllable
				(root_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5
				(tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
			Mode.TANGENT:
				gizmo.controllable = tangent_gizmo_controllable
				(root_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
				(tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5
			

func _ready() -> void:
	gizmo_set.connect(on_gizmo_set)
	velocity_tangent.velocity_set.connect(func(v : float):
		angular_velocity_amount = v
		)
	

func _process(delta: float) -> void:
	angular_velocity_tangent = (root_tangent.basis as Quaternion).get_axis()
	velocity_tangent_vector = vel_object.position

func on_gizmo_set(_gizmo : Gizmo):
	gizmo_controllable.gizmo = _gizmo
	if _gizmo:
		_gizmo.controllable = gizmo_controllable

func _input(event: InputEvent) -> void:
	if not visible or not gizmo:
		return
	if event is InputEventKey:
		if not event.pressed:
			return
		if event.keycode == KEY_S:
			mode = Mode.TANGENT if mode == Mode.POSE else Mode.POSE

func select():
	mode = Mode.POSE

func deselect():
	(root_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
	(tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1

func right_clicked_empty(pressed : bool):
	pass
