extends Resource
class_name AnimTarget

enum TargetType { OBJECT, BONE }

@export var type : TargetType
@export var node_path : NodePath
@export var bone_name : String

var _node : Node3D
var _skeleton : Skeleton3D
var _bone_idx := -1

func bind(owner : Node):
	_node = owner.get_node_or_null(node_path)

	if type == TargetType.BONE:
		_skeleton = _node
		if _skeleton:
			_bone_idx = _skeleton.find_bone(bone_name)

func get_transform() -> Transform3D:
	match type:
		TargetType.OBJECT:
			return _node.transform
		TargetType.BONE:
			return _skeleton.get_bone_pose(_bone_idx)
	return Transform3D()

func set_transform(t : Transform3D):
	match type:
		TargetType.OBJECT:
			_node.transform = t
		TargetType.BONE:
			_skeleton.set_bone_pose(_bone_idx, t)
