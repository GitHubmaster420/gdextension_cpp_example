@tool
extends VectorModifier
class_name VectorAdder

@export var add_vector : Vector3

@export var add_multi : float

@export_tool_button("push away from ball") var pb := set_to_push_away_from_ball

func set_to_push_away_from_ball():
	expression_strings = []
	expression_strings.append("{'add_vector' : -info_dic.ball_delta_flat}")
	expression_strings.append("{'add_multi' : 1}")

func modify_vector(org_v : Vector3) -> Vector3:
	return org_v + add_vector * add_multi
