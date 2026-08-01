extends MenuLabel

var foot_animator : FootAnimator:
	get:
		return get_parent().get_parent()
func select():
	foot_animator.interp_mode = FootAnimator.InterpMode.IK_HERMITE
