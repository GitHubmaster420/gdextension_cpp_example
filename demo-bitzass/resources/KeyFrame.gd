@tool
extends Resource
class_name KeyFrame

func _init(_transform : Transform3D, _frame : int, _origin_type := AnimTrack.OriginInterpType.LERP, _basis_type := AnimTrack.BasisInterpType.QUAT_SLERP, _curve : Curve = null, _velocity := Vector3.INF, _additional_info := {}) -> void:
	transform = _transform
	frame = _frame
	velocity = _velocity
	basis_type = _basis_type
	origin_type = _origin_type
	curve = _curve
	additional_info = _additional_info

@export var transform : Transform3D
@export var velocity : Vector3
@export var frame : int
@export var basis_type : AnimTrack.BasisInterpType
@export var origin_type : AnimTrack.OriginInterpType
@export var curve : Curve # TODO: Optional curve for position and rotation separately
@export var additional_info : Dictionary
