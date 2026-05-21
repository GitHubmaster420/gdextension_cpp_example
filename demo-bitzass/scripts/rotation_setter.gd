@tool
extends SkeletonModifier3D
class_name BoneRotSetter


@export var bone : String:
	set(v):
		bone = v
		if not is_node_ready():
			return
		bone_id = get_skeleton().find_bone(bone)
		

var bone_id : int

func _validate_property(property: Dictionary) -> void:
	if property.name == "bone":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()

@export var rot : Quaternion

@export_tool_button("set rest as current") var sr := set_rest_as_current

func set_rest_as_current():
	rot = get_skeleton().get_bone_rest(bone_id).basis

func _ready() -> void:
	bone = bone

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process_modification() -> void:
	if not bone:
		return
	get_skeleton().set_bone_pose_rotation(bone_id, rot)
