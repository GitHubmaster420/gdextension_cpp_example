@tool
extends VectorModifier
class_name VectorParentChanger

@export_tool_button("set expression to ball") var sb := set_expression_to_ball

func set_expression_to_ball():
	expression_strings = []
	expression_strings.append("{'org_t' : info_dic.ball_default}")
	expression_strings.append("{'new_t' : info_dic.ball_new}")

@export_tool_button("set expression to ball flat") var sbf := set_expression_to_flat_ball

func set_expression_to_flat_ball():
	expression_strings = []
	expression_strings.append("{'org_t' : info_dic.ball_default_flat}")
	expression_strings.append("{'new_t' : info_dic.ball_new_flat}")

var org_t : Transform3D
var new_t : Transform3D

func modify_vector(org_v : Vector3) -> Vector3:
	var org_v_rel := org_t.affine_inverse() * org_v
	var new_v := new_t * org_v_rel
	return new_v
