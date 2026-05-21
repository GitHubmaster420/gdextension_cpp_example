extends MenuLabel

@export var foot_animator : FootAnimator

var mode := FootAnimator.Mode.FK:
	set(v):
		mode = v
		if not is_node_ready():
			return
		foot_animator.tangent_mode = mode
		text = "tangent mode: "
		text += "IK" if mode == FootAnimator.Mode.IK else "FK"

func _ready() -> void:
	mode = mode

func select():
	if mode == FootAnimator.Mode.IK:
		mode = FootAnimator.Mode.FK
	else:
		mode = FootAnimator.Mode.IK
