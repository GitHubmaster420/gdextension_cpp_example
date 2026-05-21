@tool
extends BoneController
class_name BoneControllerCopier
## Copies object's transform relative to skeleton , should be added as a child of a skeleton

@export var copy_skeleton : Skeleton3D
@export var copy_object : Node3D

var current_transform : Transform3D
var current_basis : Basis:
	get:
		return current_transform.basis

signal set_transform_called(t : Transform3D)

func _ready() -> void:
	set_transform_called.connect(func(t : Transform3D): 
		current_transform = t
		)

func do_stuff():
	if not active:
		return
	copy_transforms()

func copy_transforms():
	transform = copy_skeleton.global_transform.affine_inverse() * (copy_object.global_transform)
	set_transform_called.emit(transform)
