@tool
extends Button

@export var animator : Animator

@export var curve_path : StringName

func _validate_property(property: Dictionary) -> void:
	if property.name == "curve_path":
		property.hint = PROPERTY_HINT_ENUM
		var names : Array[String]
		if not animator:
			return
		for c in animator.get_property_list():
			if "curve" not in c.name:
				continue
			names.append(c.name)
		property.hint_string = ",".join(names)
