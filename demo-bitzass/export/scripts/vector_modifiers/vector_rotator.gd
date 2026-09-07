@tool
extends VectorModifier
class_name VectorRotator

@export var rotate_vector : Vector3
@export var rotate_amount : float

@export_tool_button("rotate around launch angle diff") var ra = match_ball_angle_diff

func match_ball_angle_diff():
	expression_strings = []
	rotate_vector = Vector3.UP
	
	expression_strings.append("{'rotate_amount' : info_dic['angle_diff']}")

func modify_vector(org_v : Vector3) -> Vector3:
	return org_v.rotated(rotate_vector, rotate_amount)
