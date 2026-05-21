extends Node
class_name ModifierAttatcher

@export var modifiers : Array[SkeletonModifier3D]

func attach_joycon(_jc : JoyCon):
	for m in modifiers:
		m.active = true

func detatch_joycon():
	for m in modifiers:
		m.active = false
