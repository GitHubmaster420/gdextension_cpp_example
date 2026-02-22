extends MenuOption

@export var pie_menu : PieMenu

func select(jc : JoyCon):
	pie_menu.on_y_pressed(jc)
