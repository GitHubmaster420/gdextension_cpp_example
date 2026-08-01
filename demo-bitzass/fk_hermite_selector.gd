extends MenuLabel

var foot_animator : FootAnimator:
	get:
		return get_parent().get_parent()
var pie_menu : ColorRect:
	get:
		return get_parent()

func select():
	foot_animator.interp_mode = FootAnimator.InterpMode.FK_HERMITE
	pie_menu.visible = false
