@tool
extends SkeletonModifier3D
class_name CopyModifier

#goal is to

@export_enum("string") var bone : String

@export var target : Node3D

@export var offset : Basis

@export_tool_button("set offset as current") var s = set_current_rot_as_offset

@export var wait_for_finished := false

@export var wait_for_node : Node3D

@export_enum("s") var wait_for_signal_signal_name : String

@export_enum("p") var transform_path : String = ""

signal all_processed

func set_current_rot_as_offset():
	offset = target.global_basis

func _validate_property(property: Dictionary) -> void:
	if property.name == "bone":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()
	if property.name == "wait_for_signal_signal_name":
		var w := wait_for_node
		if w:
			var names : Array[String]
			property.hint = PROPERTY_HINT_ENUM
			var signals := w.get_signal_list()
			for d in signals:
				var n : String = d.name
				names.append(n)
			property.hint_string = ",".join(names)
	if property.name == "transform_path":
		var names : Array[String]
		var t := target
		if target:
			property.hint = PROPERTY_HINT_ENUM
			for p in target.get_property_list():
				if p.type == Variant.Type.TYPE_BASIS:
					names.append(p.name)
		property.hint_string = ",".join(names)
					



func _process_modification_with_delta(delta: float) -> void:
	if wait_for_finished:
		await wait_for_node.get(wait_for_signal_signal_name)
	var skeleton : Skeleton3D = get_skeleton()
	var id := skeleton.find_bone(bone)
	
	if not target or not bone:
		return
	var target_basis : Basis
	if transform_path == "":
		target_basis = target.global_basis
	else:
		target_basis = target.get(transform_path)
	skeleton.set_bone_global_pose(id, Transform3D(skeleton.global_basis.inverse() * (target_basis * offset.inverse()) * skeleton.get_bone_global_rest(id).basis ,skeleton.get_bone_global_pose(id).origin))
	all_processed.emit()
