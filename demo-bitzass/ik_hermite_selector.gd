extends MenuLabel

@export var foot_aimator : FootAnimator

func select():
	#foot_aimator.interp_mode = FootAnimator.InterpMode.IK_HERMITE
	pass
