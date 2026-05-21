@tool
extends Node
class_name GroundState

@export var ground : MeshInstance3D
#
#func _process(delta: float) -> void:
	#var frame := current_frame
	#var keys := ground_heights.keys()
	#keys.sort()
	#
	#var first_frame : int = keys[0]
	#var last_frame : int = keys[-1]
	#for i in keys:
		#if i > frame:
			#last_frame = i
			#break
		#first_frame = i
	#var t := clampf(float(frame - first_frame) / float(last_frame - first_frame), 0, 1)
	#if first_frame == last_frame:
		#t = 1
	#
	#var h := lerpf(ground_heights[first_frame], ground_heights[last_frame], t)
	#ground.position.y = h

@export var current_frame : int:
	set(frame):
		current_frame = clampi(frame, 0, anim_player.current_animation.duration * AnimPlayerModifier.FPS)
		if anim_player:
			anim_player.current_frame = current_frame

@export var anim_player : AnimPlayerModifier

@export var right_foot_states : Dictionary[int, FootState]
@export var left_foot_states : Dictionary[int, FootState]

@export var is_grounded_array : Array[bool]

@export var ground_heights : Dictionary[int, float]

var skeleton : Skeleton3D:
	get:
		return anim_player.get_skeleton()

@export_enum("right toe") var right_toe : String
@export_enum("right heel") var right_heel : String
@export_enum("left toe") var left_toe : String
@export_enum("left heel") var  left_heel : String

func _validate_property(property: Dictionary) -> void:
	if property.name == "right_toe" or property.name == "right_heel" or property.name == "left_toe" or property.name == "left_heel":
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()

enum FootState{
	GROUNDED,
	AERIAL
}

@export_tool_button("right step") var step_with_right_foot = set_foot_state.bind(true, false)
@export_tool_button("right land") var land_with_right_foot = set_foot_state.bind(true, true)
@export_tool_button("left step") var step_with_left_foot = set_foot_state.bind(false, false)
@export_tool_button("left land") var land_with_left_foot = set_foot_state.bind(false, true)

@export_tool_button("set ground height") var sgh = create_hook

func create_hook():
	await skeleton.skeleton_updated
	var lowest_height := INF
	var lowest_bone_name : String
	for bone_name : String in [right_heel, right_toe, left_heel, left_toe]:
		var height := skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin.y
		if height < lowest_height:
			lowest_height = height
			lowest_bone_name = bone_name
	ground_heights[current_frame] = lowest_height

func set_foot_state(right : bool, grounded : bool):
	var state : FootState = FootState.GROUNDED if grounded else FootState.AERIAL
	var dictionary : Dictionary[int, FootState] = right_foot_states if right else left_foot_states
	var frame := anim_player.current_frame
	dictionary[frame] = state
	bake_is_grounded()

func bake_is_grounded():
	if right_foot_states.size() == 0 or left_foot_states.size() == 0:
		return
	is_grounded_array.clear()

	var right_keys : Array[int]
	right_keys.assign(right_foot_states.keys())
	
	var left_keys : Array[int]
	left_keys.assign(left_foot_states.keys())
	right_keys.sort()
	left_keys.sort()

	var r := 0
	var l := 0
	
	var right_grounded := false
	var left_grounded := false
	
	var frame_count := int(anim_player.current_animation.duration * AnimPlayerModifier.FPS)
	var current_frame := 0

	while current_frame < frame_count:
		
		var next_right := right_keys[r] if r < right_keys.size() else frame_count
		var next_left  := left_keys[l]  if l < left_keys.size() else frame_count
		
		var next_event = mini(next_right, next_left)
		
		var grounded := right_grounded or left_grounded
		
		for i in range(current_frame, next_event):
			is_grounded_array.append(grounded)
		
		current_frame = next_event
		
		if r < right_keys.size() and next_event == next_right:
			right_grounded = right_foot_states[next_right] == FootState.GROUNDED
			r += 1
		
		if l < left_keys.size() and next_event == next_left:
			left_grounded = left_foot_states[next_left] == FootState.GROUNDED
			l += 1
	

	
