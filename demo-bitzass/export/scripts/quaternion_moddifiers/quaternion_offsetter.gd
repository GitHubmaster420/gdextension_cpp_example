@tool
class_name QuaternionOffsetter extends QuaternionModifier

@export var vector_to_totate : Vector3
@export var rotate_amount : float

@export_tool_button("rotate_with_ball") var mb = match_ball_angle_diff

func match_ball_angle_diff():
	expression_strings = []
	vector_to_totate = Vector3.UP
	
	expression_strings.append("{'rotate_amount' : info_dic['angle_diff']}")

func modify_quaternion(q_org : Quaternion) -> Quaternion:
	return Quaternion(vector_to_totate, rotate_amount) * q_org
