extends MenuLabel

@export var foot_animator : FootAnimator

var mode := FootAnimator.Mode.IK:
	set(v):
		mode = v
		if not is_node_ready():
			return
		foot_animator.pose_mode = mode

func on_foot_animator_pose_mode_changed():
	text = "pose mode: "
	text += "IK" if foot_animator.pose_mode == FootAnimator.Mode.IK else "FK"

func _ready() -> void:
	foot_animator.pose_mode_set.connect(on_foot_animator_pose_mode_changed)
	mode = mode

func select():
	if mode == FootAnimator.Mode.IK:
		mode = FootAnimator.Mode.FK
	else:
		mode = FootAnimator.Mode.IK
