@tool
class_name BallChaser
extends VectorModifier

@export var ball_position : Vector3
@export var ball_basis : Basis

@export var offset_vector : Vector3

@export_tool_button("chase ball") var cb = chase_final_ball

func chase_final_ball():
	expression_strings = []
	expression_strings.append("{'ball_position' : info_dic['final_ball_pos']}")
	expression_strings.append("{'ball_basis' : info_dic['final_ball_direction_basis']}")

func modify_vector(org_v : Vector3) -> Vector3:
	var t := Transform3D(ball_basis, ball_position)
	return t * offset_vector
