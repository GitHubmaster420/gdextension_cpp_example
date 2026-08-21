@tool
class_name FloatModifier extends Resource

@export var expression_str : String

func interpolate_float(f : float, info_dic : Dictionary) -> float:
	
	var expr := Expression.new()
	var error := expr.parse(expression_str, ["info_dic"])
	if error != OK:
		return f
	var result : Variant = expr.execute([info_dic])
	
	if expr.has_execute_failed():
		return f
	if (result is not float) and (result is not int):
		return f
	
	
	return float(result)
