extends Object
class_name Delayer

static func set_delayed(object : Object, value : Variant, _name : String, time : float, tree : SceneTree):
	await tree.create_timer(time).timeout
	DuckTyper.set_variable_duck_typed(object, _name, value)
