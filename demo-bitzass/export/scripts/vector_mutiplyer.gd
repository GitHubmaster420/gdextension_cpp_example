@tool
extends VectorModifier
class_name VectorMultiplyer

@export var multiply_amount := 1.0

func modify_vector(org_v : Vector3) -> Vector3:
	return org_v * multiply_amount
