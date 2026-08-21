@tool
@abstract class_name QuaternionModifier extends Resource

@abstract func modify_quaternion(q_org : Quaternion) -> Quaternion

@export var expression_strings : Array[String]

func modify_variables(info_dic : Dictionary) -> void:
	for expression_string in expression_strings:
		var expr := Expression.new()
		var error := expr.parse(expression_string, ["info_dic"])
		if error != OK:
			continue
		var dic : Dictionary = expr.execute([info_dic])
		set(dic.keys()[0], dic.values()[0])
