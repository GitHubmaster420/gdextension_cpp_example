extends MenuOption

@export var stick_ui : StickUI

func select(jc : JoyCon):
	stick_ui.active_jc = jc
	stick_ui.active = true
