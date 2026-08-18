@tool
extends Animator
class_name SpineAnimator

func _init() -> void:
	spine_animators.append(self)

static var spine_animators : Array[SpineAnimator]

@export var pelvis_mesh : MeshInstance3D
@export var hips_mesh : MeshInstance3D
@export var chest_mesh : MeshInstance3D

@export var pelvis_tangent_mesh: MeshInstance3D
@export var hip_tangent_mesh: MeshInstance3D
@export var chest_tangent_mesh: MeshInstance3D

@export var  pelvis_g_tangent_use_auto_tangent := true
@export var pelvis_r_tangent_use_auto_tagent:= true
@export var hips_r_tangent_use_auto_tagent := true
@export var chest_r_tangent_use_auto_tagent := true

@export var pelvis_tangent: Marker3D
@export var hip_tangent: Marker3D
@export var chest_tangent: Marker3D
@export var pelvis_loc_vel: Marker3D

@export var pelvis_g_check_button: CheckButton
@export var pelvis_r_check_button: CheckButton
@export var hips_r_check_button: CheckButton
@export var chest_r_check_button: CheckButton


@export var pelvis_velocity_tangent: VelocityTangent
@export var hip_velocity_tangent: VelocityTangent
@export var chest_velocity_tangent: VelocityTangent

@export var pelvis_g_tangent_vector : Vector3
@export var pelvis_g_tangent_magnitude : float

@export var pelvis_r_tangent_vector : Vector3

@export var hips_r_tangent_vector : Vector3

@export var chest_r_tangent_vector : Vector3


@export var pelvis_loc_ease_curve : MyEaseInOut:
	set(v):
		pelvis_loc_ease_curve = v
		pelvis_loc_ease_curve.bake_fast()
		if not is_node_ready():
			return
		pelvis_g_curve_drawer.my_ease_in_out_curve = v

@export var pelvis_rot_ease_curve : MyEaseInOut:
	set(v):
		pelvis_rot_ease_curve = v
		pelvis_rot_ease_curve.bake_fast()
		if not is_node_ready():
			return
		pelvis_r_curve_drawer.my_ease_in_out_curve = v
		
@export var hip_rot_ease_curve : MyEaseInOut:
	set(v):
		hip_rot_ease_curve = v
		hip_rot_ease_curve.bake_fast()
		if not is_node_ready():
			return
		hips_r_curve_drawe.my_ease_in_out_curve = v
@export var chest_rot_ease_curve : MyEaseInOut:
	set(v):
		chest_rot_ease_curve = v
		chest_rot_ease_curve.bake_fast()
		if not is_node_ready():
			return
		chest_r_curve_drawer.my_ease_in_out_curve = v

@export var right_side: Control

@export var pelvis_g_curve_drawer: EaseCurveDrawer
@export var pelvis_r_curve_drawer: EaseCurveDrawer
@export var hips_r_curve_drawe: EaseCurveDrawer
@export var chest_r_curve_drawer: EaseCurveDrawer


@export var pelvis_g_tangent_auto_influence : float: ## -1.0 for prev keyframe, 1.0 for next
	set(v):
		pelvis_g_tangent_auto_influence = v
		edited = edited
@export var pelvis_r_tangent_auto_influence : float: ## -1.0 for prev keyframe, 1.0 for next
	set(v):
		pelvis_r_tangent_auto_influence = v
		edited = edited
@export var hip_r_tangent_auto_influence : float: ## -1.0 for prev keyframe, 1.0 for next
	set(v):
		hip_r_tangent_auto_influence = v
		edited = edited
@export var chest_r_auto_influence : float: ## -1.0 for prev keyframe, 1.0 for next
	set(v):
		chest_r_auto_influence = v
		edited = edited

@export var pelvis_g_vel : float = 0.0: ## M/S
	set(v):
		pelvis_g_vel = v
		if not is_node_ready():
			return
		if pelvis_g_vel == 0:
			pass
@export var pelvis_r_vel : float ## RAD/S
@export var hip_r_vel : float ## RAD/S
@export var chest_r_vel : float ## RAD/S

enum Mode{
	POSE,
	TANGENT
}

@export var mode := Mode.POSE:
	set(v):
		mode = v
		var stored := current
		current = not current
		current = stored

enum Edited{
	PELVIS_G,
	PELVIS_R,
	HIP_R,
	CHEST_R
}

@export var edited := Edited.PELVIS_G:
	set(v):
		edited = v

@export var rest_transforms : Array[Transform3D]

@export var current_transforms : Array[Transform3D]

@export var gizmo_controllables : Array[GizmoControllable]
@export var tangent_controllables : Array[GizmoControllable]

@export var root : Marker3D
@export var pelvis_root : Marker3D
@export var pelvis_final : Marker3D
@export var hip_pose: Marker3D
@export var chest_pose: Marker3D

@export var skeleton : Skeleton3D

@export var first_idx := 1
@export var last_idx := 4

@export var hip_start_idx := 2

@export var multi_mesh_instance_3d: MultiMeshInstance3D


@export_tool_button("set rests") var sr := get_rest_transforms

@export var return_early := true

@export_tool_button("snap_pelvis") var sp := snap_pelvis

func snap_pelvis():
	pelvis_root.position = skeleton.get_bone_rest(first_idx).origin

func _ready() -> void:
	visibility_changed.connect(on_visibility_changed)
	edited = edited
	gizmo_set.connect(on_gizmo_set)
	var stored := current
	current = not current
	current = stored
	
	pelvis_loc_ease_curve = pelvis_loc_ease_curve
	pelvis_rot_ease_curve = pelvis_rot_ease_curve
	hip_rot_ease_curve = hip_rot_ease_curve
	chest_rot_ease_curve = chest_rot_ease_curve
	
	pelvis_g_check_button.button_pressed = pelvis_g_tangent_use_auto_tangent
	pelvis_r_check_button.button_pressed = pelvis_r_tangent_use_auto_tagent
	hips_r_check_button.button_pressed = hips_r_tangent_use_auto_tagent
	chest_r_check_button.button_pressed = chest_r_tangent_use_auto_tagent
	
	pelvis_g_check_button.toggled.connect(func(b : bool):
		pelvis_g_tangent_use_auto_tangent = b
		)
	pelvis_r_check_button.toggled.connect(func(b : bool):
		pelvis_r_tangent_use_auto_tagent = b
		)
	hips_r_check_button.toggled.connect(func(b : bool):
		hips_r_tangent_use_auto_tagent = b
		)
	chest_r_check_button.toggled.connect(func(b : bool):
		chest_r_tangent_use_auto_tagent = b
		)
	
	pelvis_velocity_tangent.velocity_set.connect(func(v : float):
		pelvis_r_vel = v
		)
	hip_velocity_tangent.velocity_set.connect(func(v : float):
		hip_r_vel = v
		)
	chest_velocity_tangent.velocity_set.connect(func(v : float):
		chest_r_vel = v
		)
	current_controllable = current_controllable
	

func on_tangent_influence_changed(value : float):
		match edited:
			Edited.PELVIS_G:
				pelvis_g_tangent_auto_influence = value
			Edited.PELVIS_R:
				pelvis_r_tangent_auto_influence = value
			Edited.HIP_R:
				hip_r_tangent_auto_influence = value
			Edited.CHEST_R:
				chest_r_auto_influence = value
		

func on_vel_changed(value : float):
	print("value: ", value)
	match edited:
		Edited.PELVIS_G:
			pelvis_g_vel = value
			print("pelvis g vel set to: ", pelvis_g_vel)
		Edited.PELVIS_R:
			pelvis_r_vel = value
		Edited.HIP_R:
			hip_r_vel = value
		Edited.CHEST_R:
			chest_r_vel = value
		

func on_visibility_changed():
	if not gizmo:
		return
	if not is_visible_in_tree():
		right_side.visible = false


func on_gizmo_mode_set(mode : Gizmo.Mode):
	if not gizmo:
		return


func on_gizmo_set(_gizmo : Gizmo):
	if not _gizmo:
		return
	if not _gizmo.mode_set.is_connected(on_gizmo_mode_set):
		_gizmo.mode_set.connect(on_gizmo_mode_set)

func _process(delta: float) -> void:
	if return_early and Engine.is_editor_hint():
		return
	if pelvis_g_tangent_use_auto_tangent:
		pelvis_loc_vel.position = pelvis_g_tangent_vector * pelvis_g_vel
	else:
		pelvis_g_tangent_vector = pelvis_loc_vel.position.normalized()
		pelvis_g_vel = pelvis_loc_vel.position.length()
	if pelvis_r_tangent_use_auto_tagent:
		pelvis_tangent.basis = Quaternion(pelvis_r_tangent_vector.normalized(), PI/2.0) as Basis if pelvis_r_tangent_vector.length_squared() > 0 else Basis.IDENTITY
	else:
		pelvis_r_tangent_vector = pelvis_tangent.basis.get_rotation_quaternion().get_axis()
	if hips_r_tangent_use_auto_tagent:
		hip_tangent.basis = Quaternion(hips_r_tangent_vector.normalized(), PI/2.0) as Basis if hips_r_tangent_vector.length_squared() > 0 else Basis.IDENTITY
	else:
		hips_r_tangent_vector = hip_tangent.basis.get_rotation_quaternion().get_axis()
	if chest_r_tangent_use_auto_tagent:
		chest_tangent.basis = Quaternion(chest_r_tangent_vector.normalized(), PI/2.0) as Basis if chest_r_tangent_vector.length_squared() > 0 else Basis.IDENTITY
	else:
		chest_r_tangent_vector = chest_tangent.basis.get_rotation_quaternion().get_axis()
	
	update_transforms()

func update_transforms():


	current_transforms = get_transforms_from_drivers(root.transform, pelvis_root.transform, hip_pose.basis, chest_pose.basis)
	
	hip_pose.global_position = current_transforms[hip_start_idx].origin
	pelvis_final.global_position = current_transforms[0].origin
	chest_pose.global_position = current_transforms[-1].origin
	for i in range(current_transforms.size()):
		multi_mesh_instance_3d.multimesh.set_instance_transform(i, current_transforms[i])

func get_transforms_from_drivers(root_global : Transform3D, pelvis_as_parent : Transform3D, hip_local : Basis, chest_local : Basis) -> Array[Transform3D]:# TODO: pass root t
	var transforms : Array[Transform3D]
	
	transforms = rest_transforms.duplicate()
	
	var pelvis_global := root_global * pelvis_as_parent
	var hip_global := pelvis_global.basis * hip_local
	var chest_global := pelvis_global.basis * chest_local
	
	var pelvis_rest := rest_transforms[0]
	
	var pelvis_offset := pelvis_global
	
	var root_rest := skeleton.get_bone_global_rest(0)
	

	
	transforms.resize(rest_transforms.size())
	
	var global_pos_offset := (pelvis_global.origin -pelvis_rest.origin)
	
	var root_delta := root_global.basis * root_rest.basis.inverse()
	
	var p := pelvis_rest.origin
	
	var p2 := root_delta * p
	
	var correction = p2 - p
	#
	#global_pos_offset += correction
	
	transforms[0].basis = (pelvis_offset * rest_transforms[0]).basis
	
	transforms[0].origin += global_pos_offset
	
	var old := transforms[0]
	
	
	
	for i in range(1, transforms.size()):
		transforms[i].basis = (pelvis_offset * rest_transforms[i]).basis
		
		transforms[i].origin = old.origin + (old.basis * rest_transforms[i - 1].basis.inverse()) * (rest_transforms[i].origin - rest_transforms[i-1].origin)
		
		old = transforms[i]

	
	old = transforms[hip_start_idx]
	
	var old_offset := pelvis_offset.basis
	
	for i in range(hip_start_idx -1, -1, -1):
		var start := pelvis_global.basis.orthonormalized()
		var end := hip_global.orthonormalized()
		var t := float(i) / float(hip_start_idx)
		
		t = 1.0 - t
		
		var offset := start.slerp(end, t)
	
		transforms[i].basis = offset * rest_transforms[i].basis
		
		transforms[i].origin = old.origin + offset * (rest_transforms[i].origin - rest_transforms[i + 1].origin)
		
		old_offset = offset
		
		old = transforms[i]
	
	old = transforms[hip_start_idx]
	
	old_offset = pelvis_offset.basis
	
	for i in range(hip_start_idx, transforms.size(), 1):
		var start := pelvis_global.basis.orthonormalized()
		var end := chest_global.orthonormalized()
		var t := float(i + 1 - hip_start_idx) / float(transforms.size() - hip_start_idx)
		
		var offset := start.slerp(end, t)
	
		transforms[i].basis = offset * rest_transforms[i].basis
		
		if i != hip_start_idx:
			transforms[i].origin = old.origin + old_offset * (rest_transforms[i].origin - rest_transforms[i - 1].origin)
		
		old_offset = offset
		
		old = transforms[i]

	
	return transforms if not Input.is_action_pressed("ui_accept") else rest_transforms

func get_rest_transforms():
	rest_transforms.clear()
	for i in range(first_idx, last_idx + 1):
		rest_transforms.append(skeleton.get_bone_global_rest(i))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = rest_transforms.size()
	for i in range(rest_transforms.size()):
		mm.set_instance_transform(i, rest_transforms[i])
	multi_mesh_instance_3d.multimesh = mm

var current_controllable : GizmoControllable:
	set(v):
		if not is_node_ready():
			return
		if current_controllable:
			current_controllable.gizmo = null
			gizmo.controllable = null
		current_controllable = v
		if not current_controllable:
			return
		current_controllable.gizmo = gizmo
		gizmo.controllable = current_controllable

var current := 0:
	set(v):
		var r := current == v
		current = v
		if current < 0:
			current = 2
		if current > 2:
			current = 0
		if r:
			return
		if gizmo:
			match mode:
				Mode.POSE:
					(pelvis_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
					(hip_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
					(chest_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
					current_controllable = gizmo_controllables[current]
					match current:
						0:
							if gizmo.mode == Gizmo.Mode.GRAB:
								edited = Edited.PELVIS_G
							else:
								edited = Edited.PELVIS_R
							(pelvis_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("selected", true)
							(hips_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("selected", false)
							(chest_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("selected", false)
							
						1:
							edited = Edited.HIP_R
							(pelvis_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("selected", false)
							(hips_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("selected", true)
							(chest_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("selected", false)
						2:
							edited = Edited.CHEST_R
							(pelvis_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("selected", false)
							(hips_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("selected", false)
							(chest_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("selected", true)
				Mode.TANGENT:
					current_controllable = tangent_controllables[current]
					(pelvis_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("selected", false)
					(hips_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("selected", false)
					(chest_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("selected", false)
					match current:
						0:
							(pelvis_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5
							(hip_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
							(chest_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
						1:
							(pelvis_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
							(hip_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5
							(chest_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
						2:
							(pelvis_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
							(hip_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.1
							(chest_tangent_mesh.get_active_material(0) as StandardMaterial3D).albedo_color.a = 0.5
						
							

func add_debug_rest():
	pass

func select():
	var stored := current
	current = not current
	current = stored
	right_side.visible = true

func deselect():
	right_side.visible = false

func right_clicked_empty(pressed : bool):
	pass

func highlight():
	set_color(Color.MAGENTA)

func also_highlight():
	set_color(Color.BROWN)

func un_highlight():
	set_color(Color.AQUA)

func set_color(c : Color):
	(pelvis_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("albedo", c)

func _input(event: InputEvent) -> void:
	if not gizmo:
		return
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_D:
				current += 1
			elif event.keycode == KEY_A:
				current -= 1
			elif event.keycode == KEY_S:
				mode = Mode.TANGENT if mode == Mode.POSE else Mode.POSE
