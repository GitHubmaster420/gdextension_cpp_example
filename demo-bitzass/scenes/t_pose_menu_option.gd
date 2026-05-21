extends MenuOption
@export var kinect: Kinect

func select(jc : JoyCon):
	kinect.tpose()
