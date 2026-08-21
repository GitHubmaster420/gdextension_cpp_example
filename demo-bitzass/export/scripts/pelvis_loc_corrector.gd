@tool
extends VectorModifier
class_name PelvisLocCorrector

## Meant to modify global y position so that hip is always at a fixed distance away from ankle

const ROOT_REST : Transform3D = Transform3D(Vector3.RIGHT,Vector3.BACK, Vector3.DOWN, Vector3.ZERO)

var old_ankle_pos : Vector3

var new_ankle_pos : Vector3

var org_root_t : Transform3D

var org_hip_pos : Vector3

@export var idx : int

func modify_variables(info_dic : Dictionary) -> void:
	var new : Vector3 = (info_dic["new_foot_ball_hit_t"] as Transform3D).origin
	new_ankle_pos = new
	var old : Vector3 = (info_dic["old_foot_ball_hit_t"] as Transform3D).origin
	old_ankle_pos = old
	
	org_hip_pos = (info_dic["old_hip_ball_hit_position"])
	
	org_root_t = info_dic["spine_root_ts"][idx]
	

func modify_vector(org_v : Vector3) -> Vector3:
	var org_v_global := (org_root_t) * org_v
	var org_distance_squared := old_ankle_pos.distance_squared_to(org_hip_pos)
	
	var new_flat_distance_squared := Vector2(new_ankle_pos.x, new_ankle_pos.z).distance_squared_to(Vector2(org_v_global.x, org_v_global.z))
	
	var height_diff := (org_distance_squared - new_flat_distance_squared)
	
	if height_diff < 0:
		height_diff = 0
	else:
		height_diff = sqrt(height_diff)
	
	var new_global := Vector3(org_v_global.x,new_ankle_pos.y + height_diff, org_v_global.z) 
	
	var new_local := (org_root_t).affine_inverse() * new_global
	
	return new_local
