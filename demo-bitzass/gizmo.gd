extends Node3D
class_name Gizmo

var selected_axis : int = -1

signal pressed
signal released

var start_grab_axis_pos := -Vector3.INF
var start_grab_plane_pos := -Vector3.INF
var start_rot_vector := -Vector3.INF

@export var x_body : StaticBody3D
@export var y_body : StaticBody3D
@export var z_body : StaticBody3D

@export var x_plane_body : StaticBody3D
@export var y_plane_body : StaticBody3D
@export var z_plane_body : StaticBody3D

@export var x_rot_mesh : MeshInstance3D
@export var x_rot_coll : CollisionShape3D
@export var x_grab_mesh : MeshInstance3D
@export var x_grab_coll : CollisionShape3D
@export var x_plane_mesh : MeshInstance3D
@export var x_plane_cube : MeshInstance3D
@export var x_plane_coll : CollisionShape3D

@export var y_rot_mesh : MeshInstance3D
@export var y_rot_coll : CollisionShape3D
@export var y_grab_mesh : MeshInstance3D
@export var y_grab_coll : CollisionShape3D
@export var y_plane_mesh : MeshInstance3D
@export var y_plane_cube : MeshInstance3D
@export var y_plane_coll : CollisionShape3D

@export var z_rot_mesh : MeshInstance3D
@export var z_rot_coll : CollisionShape3D
@export var z_grab_mesh : MeshInstance3D
@export var z_grab_coll : CollisionShape3D
@export var z_plane_mesh : MeshInstance3D
@export var z_plane_cube : MeshInstance3D
@export var z_plane_coll : CollisionShape3D

@export var super_mesh : MeshInstance3D
@export var super_body : StaticBody3D
@export var super_collision : CollisionShape3D

var rot_meshes : Array[MeshInstance3D]
var rot_collisions : Array[CollisionShape3D]

var grab_meshes : Array[MeshInstance3D]
var grab_collisions : Array[CollisionShape3D]

@export var camera : Camera3D

@export var axis_meshes : Dictionary[int, MeshInstance3D]

@export var hovered : Dictionary[int, bool] = {0 : false, 1 : false, 2 : false, 3 : false, 4 : false, 5 : false, 6 : false}


enum Mode{
	GRAB,
	ROTATE
}

var grabbable := true:
	set(v):
		grabbable = v
		if not grabbable:
			mode = Mode.ROTATE

@export var controllable : GizmoControllable:
	set(v):
		controllable = v
		if not is_node_ready():
			return
		if get_tree().current_scene == self:
			return
		if not controllable:
			visible = false
			return
		controllable.ignore = true
		visible = true
		
		global_transform = controllable.control_node.global_transform
		grabbable = controllable.grabbable

signal mode_set(_mode : Mode)

var mode : Mode:
	set(v):
		mode = v
		if not is_node_ready():
			return
		if not grabbable:
			mode = Mode.ROTATE
		match mode:
			Mode.GRAB:
				for mesh : MeshInstance3D in grab_meshes:
					mesh.visible = true
				for coll : CollisionShape3D in grab_collisions:
					coll.disabled = not true
				for mesh : MeshInstance3D in rot_meshes:
					mesh.visible = false
				for coll : CollisionShape3D in rot_collisions:
					coll.disabled = true
			Mode.ROTATE:
				for mesh : MeshInstance3D in grab_meshes:
					mesh.visible = false
				for coll : CollisionShape3D in grab_collisions:
					coll.disabled = true
				for mesh : MeshInstance3D in rot_meshes:
					mesh.visible = true
				for coll : CollisionShape3D in rot_collisions:
					coll.disabled = not true
		mode_set.emit(mode)

func _ready() -> void:
	x_body.input_ray_pickable = true
	y_body.input_ray_pickable = true
	z_body.input_ray_pickable = true
	x_plane_body.input_ray_pickable = true
	y_plane_body.input_ray_pickable = true
	z_plane_body.input_ray_pickable = true
	super_body.input_ray_pickable = true
	
	x_body.mouse_entered.connect(mouse_entered.bind(0))
	x_body.mouse_exited.connect(mouse_exited.bind(0))
	
	y_body.mouse_entered.connect(mouse_entered.bind(1))
	y_body.mouse_exited.connect(mouse_exited.bind(1))
	
	z_body.mouse_entered.connect(mouse_entered.bind(2))
	z_body.mouse_exited.connect(mouse_exited.bind(2))
	
	x_plane_body.mouse_entered.connect(mouse_entered.bind(3))
	x_plane_body.mouse_exited.connect(mouse_exited.bind(3))
	y_plane_body.mouse_entered.connect(mouse_entered.bind(4))
	y_plane_body.mouse_exited.connect(mouse_exited.bind(4))
	z_plane_body.mouse_entered.connect(mouse_entered.bind(5))
	z_plane_body.mouse_exited.connect(mouse_exited.bind(5))
	
	x_body.input_event.connect(gizmo_clicked.bind(0))
	y_body.input_event.connect(gizmo_clicked.bind(1))
	z_body.input_event.connect(gizmo_clicked.bind(2))
	
	x_plane_body.input_event.connect(gizmo_clicked.bind(3))
	y_plane_body.input_event.connect(gizmo_clicked.bind(4))
	z_plane_body.input_event.connect(gizmo_clicked.bind(5))
	
	super_body.input_event.connect(gizmo_clicked.bind(6))
	super_body.mouse_entered.connect(mouse_entered.bind(6))
	super_body.mouse_exited.connect(mouse_exited.bind(6))
	
	for i in range(7):
		mouse_exited(i)
	grab_meshes = [x_grab_mesh, y_grab_mesh, z_grab_mesh, x_plane_mesh, y_plane_mesh, z_plane_mesh, super_mesh]
	grab_collisions = [x_grab_coll, y_grab_coll, z_grab_coll, x_plane_coll, y_plane_coll, z_plane_coll, super_collision]
	rot_meshes = [x_rot_mesh, y_rot_mesh, z_rot_mesh]
	rot_collisions = [x_rot_coll, y_rot_coll, z_rot_coll]
	mode = Mode.ROTATE
	controllable = controllable

func mouse_entered(axis : int):
	if axis == 6:
		print("super entered")
	if selected_axis == -1: #If no selected axis currently, visualize
		(axis_meshes[axis].get_active_material(0) as StandardMaterial3D).albedo_color.v = 1
	hovered[axis] = true

func mouse_exited(axis : int):
	if selected_axis == -1: #If no selected axis currently, visualize
		(axis_meshes[axis].get_active_material(0) as StandardMaterial3D).albedo_color.v = 0.4
	hovered[axis] = false

func gizmo_clicked(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int, axis : int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				selected_axis = axis
				if selected_axis != -1:
					pressed.emit()
				print("gizmo clicked, axis: ", axis)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_released():
				if selected_axis != -1:
					released.emit()
					var stored := selected_axis
					selected_axis = -1
					if not hovered[stored]:
						mouse_exited(stored)
					start_grab_plane_pos = -Vector3.INF
					start_grab_axis_pos = -Vector3.INF
					start_rot_vector = -Vector3.INF
	elif event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_G:
				if event.alt_pressed:
					if controllable:
						controllable.alt_g_pressed()
					return
				mode = Mode.GRAB
			elif event.keycode == KEY_R:
				if event.alt_pressed:
					if controllable:
						controllable.alt_r_pressed()
					return
				mode = Mode.ROTATE
			
		

	elif event is InputEventMouseMotion:
		var motion : Vector2 = event.velocity
		var camera_basis := camera.global_basis
		var x_dir := camera_basis.x
		var y_dir := -camera_basis.y
		var x_motion := motion.x * x_dir
		var y_motion := motion.y * y_dir
		if selected_axis in axis_meshes:
			if selected_axis < 3:
				var axis := axis_meshes[selected_axis].global_basis.y.normalized()
				match mode:
					Mode.ROTATE:
						var plane := Plane(global_basis[selected_axis].normalized(), global_position)
						
						var origin := camera.project_ray_origin(get_viewport().get_mouse_position())
						var dir := camera.project_ray_normal(get_viewport().get_mouse_position())
						
						var rotate_around := global_basis[selected_axis].normalized()
						
						var intersect_point = plane.intersects_ray(origin, dir)
						
						if intersect_point == null:
							return
						var angle := (intersect_point as Vector3 - global_position).signed_angle_to(start_rot_vector, rotate_around)
					
						if start_rot_vector == -Vector3.INF:
							start_rot_vector = intersect_point as Vector3 - global_position
							return
						var delta_a := -angle
						#var dot_axis := axis.cross(camera.global_basis.z).normalized()
						#var dot := dot_axis.dot(x_motion) + dot_axis.dot(y_motion)
						#var sens := 0.0005
						#print("rotating around: ", axis, "by: ", dot * sens)
						rotate(axis.normalized(), delta_a)
						start_rot_vector = intersect_point as Vector3 - global_position
					Mode.GRAB:
						#var dot := axis.dot(x_motion) + axis.dot(y_motion)
						#var sens := 0.00001 * PI
						#position += sens * dot * basis[selected_axis]
						var plane := Plane(camera.global_basis.z, global_position)
						
						var origin := camera.project_ray_origin(get_viewport().get_mouse_position())
						var normal := camera.project_ray_normal(get_viewport().get_mouse_position())
						
						var intersect_point = plane.intersects_ray(origin, normal)
						if intersect_point == null:
							return
						if start_grab_axis_pos == -Vector3.INF:
							start_grab_axis_pos = intersect_point
							return
						var delta_p := intersect_point as Vector3 - start_grab_axis_pos
						global_position += global_basis[selected_axis] * delta_p.dot(global_basis[selected_axis])
						start_grab_axis_pos = intersect_point
			elif selected_axis < 6:
				match mode:
					Mode.GRAB:
						var plane := Plane(global_basis[selected_axis - 3].normalized(), global_position)
						
						var origin := camera.project_ray_origin(get_viewport().get_mouse_position())
						var normal := camera.project_ray_normal(get_viewport().get_mouse_position())
						
						var intersect_point = plane.intersects_ray(origin, normal)
						if intersect_point == null:
							return
						if start_grab_plane_pos == -Vector3.INF:
							start_grab_plane_pos = intersect_point
							return
						var delta_p := intersect_point as Vector3 - start_grab_plane_pos
						global_position += delta_p
						start_grab_plane_pos = intersect_point
			else:
				match mode:
					Mode.GRAB:
						#var dot := axis.dot(x_motion) + axis.dot(y_motion)
						#var sens := 0.00001 * PI
						#position += sens * dot * basis[selected_axis]
						var plane := Plane(camera.global_basis.z, global_position)
						
						var origin := camera.project_ray_origin(get_viewport().get_mouse_position())
						var normal := camera.project_ray_normal(get_viewport().get_mouse_position())
						
						var intersect_point = plane.intersects_ray(origin, normal)
						if intersect_point == null:
							return
						if start_grab_axis_pos == -Vector3.INF:
							start_grab_axis_pos = intersect_point
							return
						var delta_p := intersect_point as Vector3 - start_grab_axis_pos
						global_position += delta_p
						start_grab_axis_pos = intersect_point

							
						

func _process(delta: float) -> void:
	if not controllable:
		return
	if not controllable.grabbable:
		global_position = controllable.control_node.global_position
