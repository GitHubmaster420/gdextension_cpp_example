@tool
extends VectorModifier
class_name VectorPivoter

@export var mirror_amount := 1.0

@export var mirror_vector : Vector3

func modify_vector(org_v : Vector3) -> Vector3:
	return mirror_vector.lerp(org_v, mirror_amount)
