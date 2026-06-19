@abstract class_name BodyPartInterpolator extends SkeletonModifier3D


const SHARED_TRACK_ACCESSORS = {
	"TRACK_TYPE" : "type",
	"LOCATION" : "location",
	"ROTATION" : "rotation" ,
	"VELOCITY" : "velocity",
	"ANGULAR_VELOCITY" : "angular_velocity"
}

var prev_keyframe : Keyframe:
	get:
		return anim_track_holder.keyframes[prev_keyframe_idx]
var next_keyframe : Keyframe:
	get:
		return anim_track_holder.keyframes[next_keyframe_idx]

var prev_keyframe_idx : int = -1
var next_keyframe_idx : int = -1


@export var anim_track_holder : AnimTrackHolder

@export var editing := true

@export_range(0.0, 10.0, 0.03333) var animation_length : float:
	set(v):
		animation_length = v
		current_time = min(current_time, animation_length)

@export_range(0.0, 10.0, 0.03333) var current_time : float:
	set(v):
		current_time = min(v, animation_length)

func _ready() -> void:
	anim_track_holder.time_changed.connect(on_time_changed)
	anim_track_holder.keyframe_added.connect(on_keyframe_added)

func get_t_from_keyframes(time : float, k1 := prev_keyframe, k2 := next_keyframe) -> float:
	if k1 == k2:
		return 0
	return clampf(remap(time, k1.time, k2.time, 0, 1), 0, 1)


func get_next_and_prev_keyframes_indices(t : float) -> Array[int]:
	return anim_track_holder.get_next_and_prev_keyframes_indices(t)

func on_time_changed(t : float):
	current_time = t
	if anim_track_holder.keyframes.size() == 0:
		return
	var indices := get_next_and_prev_keyframes_indices(t)
	prev_keyframe_idx = indices[0]
	next_keyframe_idx = indices[1]
	print("prev: ", prev_keyframe_idx, " next: ", next_keyframe_idx)

@abstract func interpolate_keyframes()
@abstract func on_keyframe_added(key : Keyframe)
