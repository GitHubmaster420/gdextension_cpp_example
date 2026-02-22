extends Resource
class_name AnimationRes

@export var tracks : Dictionary[AnimTarget, AnimTrack]

func bind_all(owner : Node):
	for target : AnimTarget in tracks.keys():
		target.bind(owner)
