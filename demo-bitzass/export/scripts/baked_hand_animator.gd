extends BakedAnimator
class_name BakedHandAnimator

@export var ik_roll : float
@export var ik_hand_transform : Transform3D

@export var shoulder_quat : Quaternion
@export var up_arm_quat : Quaternion
@export var fore_arm_quat : Quaternion
@export var hand_quat : Quaternion

@export var shoulder_tangent_vector : Vector3
@export var shoulder_tangent_magnitude : float

@export var up_arm_tangent_vector : Vector3
@export var up_arm_tangent_magnitude : float

@export var fore_arm_tangent_vector : Vector3
@export var fore_arm_tangent_magnitude : float

@export var hand_tangent_vector : Vector3
@export var hand_tangent_magnitude : float

@export var shoulder_ease_curve : MyEaseInOut
@export var up_arm_ease_curve : MyEaseInOut
@export var fore_arm_ease_curve : MyEaseInOut
@export var hand_ease_curve : MyEaseInOut
