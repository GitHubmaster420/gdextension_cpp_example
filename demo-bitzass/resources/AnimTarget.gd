@tool
extends Resource
class_name AnimTarget

enum TargetType { OBJECT, BONE }

@export var type : TargetType
@export var node_path : NodePath
@export var bone_name : String

var _node : Node3D
var _skeleton : Skeleton3D
var _bone_idx := -1

var owner : Node

func call_init(_type : TargetType, _node_path : NodePath, _owner : Node, _bone_name := "") -> void:
	type = _type
	node_path = _node_path
	if type == TargetType.BONE:
		bone_name = _bone_name
	bind(_owner)

func bind(_owner : Node):
	owner = _owner
	_node = owner.get_node(node_path)
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

func set_additional_info(info : Dictionary):
	match type:
		TargetType.OBJECT:
			for stuff in info:
				_node.set(stuff, info[stuff]) #calling this so setters get called
		TargetType.BONE:
			for stuff in info:
				_skeleton.set_bone_meta(_skeleton.find_bone(bone_name), stuff, info[stuff])

func set_transform(t : Transform3D):
	match type:
		TargetType.OBJECT:
			_node.transform = t
			DuckTyper.call_signal_duck_typed(_node, "set_transform_called", t)
		TargetType.BONE:
			_skeleton.set_bone_pose(_bone_idx, t)
