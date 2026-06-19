extends MenuLabel

@export var foot_animator : FootAnimator

@export var pie_menu : ColorRect

func select():
	foot_animator.interp_mode = FootAnimator.InterpMode.FK_SLERP
	pie_menu.visible = false
