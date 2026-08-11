extends Animator
class_name HeadAnimator

@export var right_side: Control

@export var chest: Marker3D
@export var neck: Marker3D
@export var head: Marker3D
@export var neck_2: Marker3D

@export var neck_control: Marker3D

@export var neck_tangent: Marker3D
@export var neck_tangent_vector : Vector3
@export var neck_vel_magnitude : float
@export var neck_velocity_tangent: VelocityTangent

@export var neck_mesh: MeshInstance3D
@export var head_mesh: MeshInstance3D
@export var neck_tangent_mesh: MeshInstance3D
@export var head_tangent_mesh: MeshInstance3D


@export var head_tangent: Marker3D
@export var head_tangent_vector : Vector3
@export var head_vel_magnitude : float
@export var head_velocity_tangent: VelocityTangent

@export var pose_gizmo_controllables : Array[GizmoControllable]
@export var tangent_gizmo_controllables : Array[GizmoControllable]

@export var skeleton_3d: Skeleton3D

@export var neck_rests : Array[Transform3D]

var current_gizmoable : GizmoControllable:
	set(v):
		if current_gizmoable:
			current_gizmoable.gizmo = null
		current_gizmoable = v
		if not current_gizmoable:
			return
		current_gizmoable.gizmo = gizmo
		gizmo.controllable = current_gizmoable

var current := 0:
	set(v):
		current = v
		if not is_node_ready():
			return
		if current < 0:
			current = 1
		if current > 1:
			current = 0
		(neck_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("selected", false)
		var head_mat := head_mesh.get_active_material(0) as StandardMaterial3D
		var neck_tan_mat := neck_tangent_mesh.get_active_material(0) as StandardMaterial3D
		var head_tan_mat := head_tangent_mesh.get_active_material(0) as StandardMaterial3D
		for mat : StandardMaterial3D in [head_mat, neck_tan_mat, head_tan_mat]:
			mat.albedo_color.a = 0.1
		if not gizmo:
			return
		var gizmo_controllables : Array[GizmoControllable]
		if edited == Edited.POSE:
			gizmo_controllables = pose_gizmo_controllables
			if current == 0:
				(neck_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("selected", true)
			else:
				head_mat.albedo_color.a = 0.5
		else:
			gizmo_controllables = tangent_gizmo_controllables
			if current == 0:
				neck_tan_mat.albedo_color.a = 0.5
			else:
				head_tan_mat.albedo_color.a = 0.5
		current_gizmoable = gizmo_controllables[current]
		

enum Edited{
	POSE,
	TANGENT
}

var edited := Edited.POSE:
	set(v):
		edited = v
		if not is_node_ready():
			return
		current = current

@export var neck_ease_drawer: EaseCurveDrawer
@export var head_ease_drawer: EaseCurveDrawer

@export var neck_ease_curve : MyEaseInOut:
	set(v):
		neck_ease_curve = v
		neck_ease_curve.bake_fast()
		if not is_node_ready():
			return
		neck_ease_drawer.my_ease_in_out_curve = v
@export var head_ease_curve : MyEaseInOut:
	set(v):
		head_ease_curve = v
		head_ease_curve.bake_fast()
		if not is_node_ready():
			return
		head_ease_drawer.my_ease_in_out_curve = v

func _ready() -> void:
	neck_velocity_tangent.velocity_set.connect(func(v : float):
		neck_vel_magnitude = v
		)
	head_velocity_tangent.velocity_set.connect(func(v : float):
		head_vel_magnitude = v
		)
	current = current
	edited = edited
	head_ease_curve = head_ease_curve
	neck_ease_curve = neck_ease_curve
	visibility_changed.connect(func():
		if not is_visible_in_tree():
			right_side.visible = false
		)
	
func _process(delta: float) -> void:
	
	var bees := interpolate_neck(neck_control.basis)
	
	neck.basis = bees[0]
	neck_2.basis = bees[1]
	
	neck_tangent_vector = neck_tangent.basis.get_rotation_quaternion().get_axis()
	head_tangent_vector = head_tangent.basis.get_rotation_quaternion().get_axis()
	

func interpolate_neck(neck_basis : Basis) -> Array[Basis]:
	var offset := neck_basis.slerp(Basis.IDENTITY, 0.5)
	
	var b1 := offset * neck_rests[0].basis
	var b2 := offset * neck_rests[1].basis
	
	return [b1, b2]

func select():
	right_side.visible = true
	current = current
	
func deselect():
	right_side.visible = false
	current = current

func right_clicked_empty(pressed : bool):
	pass

func _input(event: InputEvent) -> void:
	if not gizmo or not visible:
		return
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_D:
				current += 1
			if event.keycode == KEY_A:
				current -= 1
			if event.keycode == KEY_S:
				if edited == Edited.POSE:
					edited = Edited.TANGENT
				else:
					edited = Edited.POSE
