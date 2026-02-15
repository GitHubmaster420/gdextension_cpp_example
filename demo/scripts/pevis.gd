@tool
extends MeshInstance3D
class_name Pelvis

@export var target : Node3D

@export var start_pos : Vector3

@export var movement_scale := 1.0

@export var target_start_pos : Vector3
@export var target_pos : Vector3

@export_enum("bone") var bone : String

@export_enum("up_leg") var up_leg : String
@export_enum("down_leg") var down_leg : String
@export_enum("foot") var foot : String

@export var skeleton_3d: Skeleton3D

@export var kinect_thigh : KinectJoint
@export var kinect_shin : KinectJoint
@export var kinect_foot : KinectJoint

func calculate_scale():
	var thigh_pos := skeleton_3d.get_bone_global_rest(skeleton_3d.find_bone(up_leg)).origin
	var shin_pos := skeleton_3d.get_bone_global_rest(skeleton_3d.find_bone(down_leg)).origin
	var foot_pos := skeleton_3d.get_bone_global_rest(skeleton_3d.find_bone(foot)).origin
	var armature_leg_size := thigh_pos.distance_to(shin_pos) + shin_pos.distance_to(foot_pos)
	
	var kinect_leg_size := kinect_thigh.global_position.distance_to(kinect_shin.global_position) + kinect_shin.global_position.distance_to(kinect_foot.global_position)
	
	movement_scale = armature_leg_size / kinect_leg_size
	
func _ready() -> void:
	start_pos = global_position

func _validate_property(property: Dictionary) -> void:
		if property.name == "bone":
			if skeleton_3d:
				property.hint = PROPERTY_HINT_ENUM
				property.hint_string = skeleton_3d.get_concatenated_bone_names()
				#works
		if property.name == "up_leg":
			if skeleton_3d:
				property.hint = PROPERTY_HINT_ENUM
				property.hint_string = skeleton_3d.get_concatenated_bone_names()
				#works
		if property.name == "down_leg":
			if skeleton_3d:
				property.hint = PROPERTY_HINT_ENUM
				property.hint_string = skeleton_3d.get_concatenated_bone_names()
				#works
		if property.name == "foot":
			if skeleton_3d:
				property.hint = PROPERTY_HINT_ENUM
				property.hint_string = skeleton_3d.get_concatenated_bone_names()
				#works
		

@export_tool_button("copy bone pos") var cbp = copy_bone_pos

@export_tool_button("set start pos") var ss = set_start_pos

@export_tool_button("update position") var u = update_position

@export_tool_button("set target start pos") var s = set_target_start_pos

func copy_bone_pos():
	start_pos = skeleton_3d.global_transform * (skeleton_3d.get_bone_global_rest(skeleton_3d.find_bone(bone))).origin

func set_start_pos():
	start_pos = global_position

func set_target_start_pos():
	target_start_pos = target.global_position

func set_target_pos():
	target_pos = target.global_position

func update_position():
	global_position = start_pos + (target_pos - target_start_pos) * movement_scale

func _process(delta: float) -> void:
	set_target_pos()
	update_position()
