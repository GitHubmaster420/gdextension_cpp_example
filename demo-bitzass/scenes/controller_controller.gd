@tool
extends SkeletonModifier3D

class_name ControllerController

@export var controllers : Array[BoneController]

@export var skeleton : Skeleton3D

signal all_updated

func _process_modification() -> void:
	for c in controllers:
		if c.active:
			c.do_stuff()
	all_updated.emit()
