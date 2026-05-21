@tool
extends SkeletonModifier3D
class_name CopyOtherArmatureBone

var other_updated := false

@export var other_skeleton : Skeleton3D

@export_enum("string") var other_bone : String

@export_enum("string") var this_bone : String

@export var await_node : SkeletonModifier3D
@export_enum("s") var await_signal : String

func _validate_property(property: Dictionary) -> void:
	if property.name == "other_bone":
		var skeleton := other_skeleton
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()
	if property.name == "this_bone":
		var skeleton := get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()
	if property.name == "await_signal":
		if await_node:
			var w := await_node
			var signals := w.get_signal_list()
			var names : Array[String]
			for d in signals:
				var n : String = d.name
				names.append(n)
			property.hint_string = ",".join(names)

func _process_modification_with_delta(delta: float) -> void:
	if not other_skeleton:
		return
	# might wait one extra frame but who cares
	await other_skeleton.skeleton_updated
	if other_skeleton.get_bone_pose(get_skeleton().find_bone(other_bone)).basis.determinant() == 0:
		return
	get_skeleton().set_bone_pose(get_skeleton().find_bone(this_bone), other_skeleton.get_bone_pose(get_skeleton().find_bone(other_bone)))
	
