@tool
class_name QuaternionParentChanger extends QuaternionModifier

var original_quat : Quaternion
var new_quat : Quaternion

@export_tool_button("set expression to ball") var sb := set_expression_to_ball

func set_expression_to_ball():
	expression_strings = []
	expression_strings.append("{'original_quat' : info_dic.ball_default.basis.get_rotation_quaternion()}")
	expression_strings.append("{'new_quat' : info_dic.ball_new.basis.get_rotation_quaternion()}")

@export_tool_button("set expression to ball flat") var sbf := set_expression_to_flat_ball

func set_expression_to_flat_ball():
	expression_strings = []
	expression_strings.append("{'original_quat' : info_dic.ball_default_flat.basis.get_rotation_quaternion()}")
	expression_strings.append("{'new_quat' : info_dic.ball_new_flat.basis.get_rotation_quaternion()}")

func modify_quaternion(q_org : Quaternion) -> Quaternion:
	
	var q_rel := original_quat.inverse() * q_org
	
	var q_new := new_quat * q_rel
	
	return q_new
