extends BakedAnimator
class_name BakedSpineAnimator

@export var pelvis_transform : Transform3D
@export var hip_quat : Quaternion
@export var chest_quat : Quaternion

@export var pelvis_rot_tangent_vector : Vector3
@export var pelvis_rot_tangent_magnitude : float
@export var pelvis_rot_curve : MyEaseInOut

@export var hip_rot_tangent_vector : Vector3
@export var hip_rot_tangent_magnitude : float
@export var hip_rot_curve : MyEaseInOut

@export var chest_rot_tangent_vector : Vector3
@export var chest_rot_tangent_magnitude : float
@export var chest_rot_curve : MyEaseInOut

@export var pelvis_loc_tangent_vector : Vector3
@export var pelvis_loc_tangent_magnitude : float
@export var pelvis_loc_curve : MyEaseInOut
