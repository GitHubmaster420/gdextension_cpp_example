extends Node
class_name JoyConAttachment

var joy_con : JoyCon

func attach_joycon(jc : JoyCon):
	print("attatching joycon")
	joy_con = jc
	for c in get_children():
		DuckTyper.call_func_duck_typed(c, "attach_joycon", joy_con)

func detatch_joycon():
	joy_con = null
	for c in get_children():
		DuckTyper.call_func_duck_typed(c, "detatch_joycon")

func calibrate_joycon():
	for c in get_children():
		DuckTyper.call_func_duck_typed(c, "calibrate_joycon", joy_con)
