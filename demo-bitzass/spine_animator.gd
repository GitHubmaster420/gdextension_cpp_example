@tool
extends Animator
class_name SpineAnimator


@export var rest_transforms : Array[Transform3D]

@export var current_transforms : Array[Transform3D]

@export var gizmo_controllables : Array[GizmoControllable]

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
	pelvis_root.global_position = skeleton.get_bone_global_rest(first_idx).origin

func _process(delta: float) -> void:
	if return_early:
		return
	update_transforms()

func update_transforms():

	var rests := rest_transforms
	
	var super_t := pelvis_root.global_transform
	
	var delta_position := pelvis_root.global_position - rests[0].origin
	var hip_b := hip_pose.global_basis.orthonormalized()
	var chest_b := chest_pose.global_basis.orthonormalized()
	var pelvis_t := pelvis_final.global_transform.orthonormalized()
	
	current_transforms.clear()
	current_transforms.resize(last_idx - first_idx + 1)
	current_transforms.fill(Transform3D())
	
	var offset : Vector3
	
	var hips_to_pelvis := rests[hip_start_idx].origin - rests[0].origin
	
	offset =  super_t.basis * hips_to_pelvis - hips_to_pelvis
	
	var hip_start_basis := pelvis_t.basis
	var hip_start_origin := rests[hip_start_idx].origin + delta_position + offset
	var hip_start_t := Transform3D(hip_start_basis, hip_start_origin)
	var prev_rest := rests[hip_start_idx]
	current_transforms[hip_start_idx].basis = super_t.basis
	current_transforms[hip_start_idx].origin = hip_start_t.origin
	#hip_start_basis = hip_start_basis.orthonormalized()
	var prev_pos := prev_rest.origin + delta_position + offset
	for i in range(hip_start_idx - 1, -1, -1):
		var b := super_t.basis.orthonormalized().slerp(hip_b, 1.0 - float(i) / float(hip_start_idx))
		var this_rest_pos := rest_transforms[i].origin
		var delta := this_rest_pos - prev_rest.origin
		var new := rests[i]
		new.basis = (new.basis * b).orthonormalized()
		new.origin = prev_pos + rests[i].basis.inverse() * new.basis * delta
		prev_pos = new.origin
		prev_rest = rests[i]
		current_transforms[i] = new
	prev_rest = rests[hip_start_idx]
	prev_pos = prev_rest.origin + delta_position + offset
	var old_b := super_t.basis
	for i in range(hip_start_idx, last_idx - first_idx + hip_start_idx - 1):
		var t := float(i - hip_start_idx + 1) / float((last_idx - first_idx) - (hip_start_idx) + 1)
		var b := super_t.basis.slerp(chest_b, t)
		var this_rest_pos := rest_transforms[i].origin
		var delta := this_rest_pos - prev_rest.origin
		var new := rests[i]
		var old := rests[i - 1]
		old.basis = (old.basis * old_b).orthonormalized()
		old_b = b
		new.basis = (new.basis * b).orthonormalized()
		new.origin = prev_pos + rests[i - 1].basis.inverse() * old.basis * delta
		prev_pos = new.origin
		prev_rest = rests[i]
		current_transforms[i] = new
	hip_pose.global_position = hip_start_t.origin
	pelvis_final.global_position = current_transforms[0].origin
	chest_pose.global_position = current_transforms[-1].origin
	for i in range(current_transforms.size()):
		multi_mesh_instance_3d.multimesh.set_instance_transform(i, current_transforms[i])
		
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
		current = v
		if current < 0:
			current = 2
		if current > 2:
			current = 0
		if gizmo:
			current_controllable = gizmo_controllables[current]

func add_debug_rest():
	pass

func select():
	pass

func deselect():
	pass

func right_clicked_empty(pressed : bool):
	pass

func _input(event: InputEvent) -> void:
	if not gizmo:
		return
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_D:
				current += 1
			elif event.keycode == KEY_A:
				current -= 1
