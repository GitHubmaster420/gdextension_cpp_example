@tool
extends QuaternionModifier
class_name QuaternionPivoter

@export var mirror_quaternion : Quaternion

@export var mirror_amount := 1.0

@export var quat_channel_name:  String
@export var quat_channel_idx : int

@export_tool_button("set expression to channel") var se := set_expression_to_channel

@export var test_dictionary : Dictionary

func set_expression_to_channel():
	expression_strings = []
	expression_strings.append(
		"{'mirror_quaternion' : info_dic['org_transforms'][" +str(quat_channel_name) + "][" + str(quat_channel_idx) + "]}"
	)

func modify_quaternion(q_org : Quaternion) -> Quaternion:
	return mirror_quaternion.slerp(q_org, mirror_amount)
