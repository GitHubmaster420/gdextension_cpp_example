@tool
class_name QuaternionOffsetter extends QuaternionModifier

@export var vector_to_totate : Vector3
@export var rotate_amount : float

func modify_quaternion(q_org : Quaternion) -> Quaternion:
	return Quaternion(vector_to_totate, rotate_amount) * q_org
