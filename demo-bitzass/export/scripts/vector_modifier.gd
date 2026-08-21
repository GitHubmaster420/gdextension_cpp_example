@tool
@abstract class_name VectorModifier extends Resource

@export var expression_strings : Array[String]

@abstract func modify_vector(org_v : Vector3) -> Vector3

func modify_variables(info_dic : Dictionary) -> void:
	for expression_string in expression_strings:
		var expr := Expression.new()
		var error := expr.parse(expression_string, ["info_dic"])
		if error != OK:
			continue
		var dic : Dictionary = expr.execute([info_dic])
		set(dic.keys()[0], dic.values()[0])
