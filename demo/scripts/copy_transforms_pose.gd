@tool
extends SkeletonModifier3D
class_name CopyModifierPose

@export_enum("string") var bone : String

@export var target : Node3D

@export var offset : Basis

@export_tool_button("set offset as current") var s = set_current_rot_as_offset

var reference_basis : Basis

func _ready() -> void:
	reference_basis = get_skeleton().get_bone_global_rest(get_skeleton().find_bone(bone)).basis

func set_current_rot_as_offset():
	offset = target.global_basis

func _validate_property(property: Dictionary) -> void:
	if property.name == "bone":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()



func _process_modification_with_delta(delta: float) -> void:
	if not bone or not target:
		return
	var skeleton : Skeleton3D = get_skeleton()
	var id := skeleton.find_bone(bone)
	
	skeleton.set_bone_global_pose(id, Transform3D(skeleton.global_basis.inverse() * (target.global_basis * offset.inverse()) * reference_basis ,skeleton.get_bone_global_pose(id).origin))
	
