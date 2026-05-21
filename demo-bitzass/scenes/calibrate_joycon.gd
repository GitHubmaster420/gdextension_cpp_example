extends MenuOption

@export var menu : CanvasItem

func select(jc : JoyCon):
	if not menu:
		return
	DuckTyper.call_func_duck_typed(menu, "select", jc)
