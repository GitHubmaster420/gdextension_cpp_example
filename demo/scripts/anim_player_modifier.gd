@tool
extends SkeletonModifier3D
class_name AnimPlayerModifier


const FPS = 30.0

@export var bone_filters : Dictionary[String, bool]

@export_tool_button("fill dictionary") var f = fill_bool_dictionary

@export var object_filters : Dictionary[Node3D, bool]

@export var apply_on_top := false

var current_time : float
var current_frame : int:
	get:
		return floori(current_time * FPS)

func fill_bool_dictionary():
	for i in get_skeleton().get_bone_count():
		bone_filters[get_skeleton().get_bone_name(i)] = true

@export var animations : Dictionary[String, AnimationRes]

var current_animation : AnimationRes:
	get:
		return animations[current_animation_name]

@export_enum("current_anim_name") var current_animation_name : String

func _validate_property(property: Dictionary) -> void:
	if property.name == "current_anim_name":
		property.hint = PROPERTY_HINT_ENUM
		var names : Array[String]
		for key in animations.keys():
			names.append(key)
		property.hint_string = ",".join(names)

func fill_bone_tracks(name : String):
	for key in bone_filters.keys():
		if bone_filters[key]:
			var anim_target := AnimTarget.new()
			anim_target.type = AnimTarget.TargetType.BONE
			anim_target.bone_name = key
			anim_target.node_path = get_skeleton().get_path()
			animations[name].tracks[anim_target] = AnimTrack.new()

func update_owner():
	for anim_name in animations.keys(): #Done to get autocomplete
		animations[anim_name].bind_all(get_tree().root)

func _process_modification_with_delta(_delta: float) -> void:
	if apply_on_top:
		await get_skeleton().skeleton_updated
