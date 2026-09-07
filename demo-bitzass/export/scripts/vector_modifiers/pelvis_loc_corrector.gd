@tool
extends VectorModifier
class_name PelvisLocCorrector

## Meant to modify global y position so that hip is always at a fixed distance away from ankle

const ROOT_REST : Transform3D = Transform3D(Vector3.RIGHT,Vector3.BACK, Vector3.DOWN, Vector3.ZERO)

var old_ankle_pos : Vector3

var new_ankle_pos : Vector3

var org_root_t : Transform3D

var org_hip_pos : Vector3

var new_hip_pos : Vector3

@export var idx : int

@export var max_height_diff := INF

func modify_variables_after_overrides(org_transforms : Dictionary, new_transfroms : Dictionary) -> void:
	var new : Vector3 = (new_transfroms["foot_ball_hit_t"] as Transform3D).origin
	new_ankle_pos = new
	var old : Vector3 = (org_transforms["foot_ball_hit_t"] as Transform3D).origin
	old_ankle_pos = old
	
	org_root_t = org_transforms["spine_root_ts"][idx]
	
	org_hip_pos = org_root_t * Transform3D(org_transforms["pelvis_quats"][idx], new_transfroms["pelvis_locs"][idx]) * BakedAnimationPlayer.THIGH_LOCAL_POS
	
	new_hip_pos = new_transfroms["hip_ball_hit_pos"]
	

func modify_vector(org_v : Vector3) -> Vector3:
	var org_v_global := (org_root_t) * org_v
	var org_distance_squared := old_ankle_pos.distance_squared_to(org_hip_pos)
	
	
	var new_flat_distance_squared := Vector2(new_ankle_pos.x, new_ankle_pos.z).distance_squared_to(Vector2(new_hip_pos.x, new_hip_pos.z))
	
	var height_diff := (org_distance_squared - new_flat_distance_squared) + org_v_global.y - new_hip_pos.y
	
	height_diff = minf(max_height_diff, height_diff)
	
	if height_diff < 0:
		height_diff = 0
	else:
		height_diff = sqrt(height_diff)
	
	var new_global := Vector3(org_v_global.x,new_ankle_pos.y + height_diff, org_v_global.z) 
	
	var new_local := (org_root_t).affine_inverse() * new_global
	
	return new_local
