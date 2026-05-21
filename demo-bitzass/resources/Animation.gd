@tool
extends Resource
class_name AnimationRes

@export var tracks : Dictionary[AnimTarget, AnimTrack]

@export var current_time : float

@export var duration : float

func assign_keyframe(target : AnimTarget, owner : Node3D):
	target.owner = owner
	var k := KeyFrame.new(target.get_transform(), current_time * AnimPlayerModifier.FPS)
	tracks[target].add_keyframe(k)

func bind_all(owner : Node):
	for target : AnimTarget in tracks.keys():
		if target:
			target.bind(owner)
