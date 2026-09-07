@tool
class_name FloatModifier extends Resource

@export var expression_str : String

@export_tool_button("ake ik roll") var mi = add_roll

func add_roll():
	expression_str = "f+ info_dic['angle_diff']"

@export_tool_button("match ball vel") var mb = set_to_ball_vel

func set_to_ball_vel():
	expression_str = "info_dic['flat_vel']"

func interpolate_float(f : float, info_dic : Dictionary) -> float:
	
	var expr := Expression.new()
	var error := expr.parse(expression_str, ["f", "info_dic"])
	if error != OK:
		return f
	var result : Variant = expr.execute([f, info_dic])
	
	if expr.has_execute_failed():
		return f
	if (result is not float) and (result is not int):
		return f
	
	
	return float(result)
