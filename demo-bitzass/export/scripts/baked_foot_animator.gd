class_name BakedFootAnimator extends BakedAnimator

@export var is_on_ground : bool

@export var supports_ball_contact := false
@export var after_ball_contact := false

enum InterpMode{
	CONSTANT,
	FK_HERMITE,
	IK
}

@export var interp_mode : InterpMode

enum Parent{
	ROOT,
	SPINE,
	PREV_ANIMATOR
}

@export var parent := Parent.SPINE

@export var ik_roll : float
@export var ik_foot_transform : Transform3D

@export var thigh_quat : Quaternion
@export var shin_quat : Quaternion
@export var foot_quat : Quaternion


@export var thigh_tangent_vector : Vector3
@export var thigh_tangent_magnitude : float

@export var shin_tangent_vector : Vector3
@export var shin_tangent_magnitude : float

@export var foot_tangent_vector : Vector3
@export var foot_tangent_magnitude : float

@export var thigh_ease_curve : MyEaseInOut
@export var shin_ease_curve : MyEaseInOut
@export var foot_ease_curve : MyEaseInOut
