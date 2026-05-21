extends MenuOption
class_name JcAttatcher

@export var world : World
@export var att : JoyConAttachment



func select(jc : JoyCon):
	print("selecting joycon attatcher")
	jc.attachment = att
