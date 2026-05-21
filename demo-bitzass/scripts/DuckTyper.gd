extends Object
class_name DuckTyper

static func call_func_duck_typed(target : Object, func_name : String, ...args : Array) -> bool:
	if target.has_method(func_name):
		target.callv(func_name, args)
		return true
	return false

static func set_variable_duck_typed(target : Object, var_name : String, value : Variant):
	if var_name in target:
		target.set(var_name, value)

static func call_signal_duck_typed(target : Object, signal_name : String, ...args : Array):
	if target.has_signal(signal_name):
		target.emit_signal.callv([signal_name] + args)
