extends MenuLabel

var foot_animator : FootAnimator:
	get:
		return get_parent().get_parent()

func _ready() -> void:
	foot_animator.on_ground_set.connect(func():
		text = "Grounded" if foot_animator.is_on_ground else "On air"
		)

func select():
	foot_animator.is_on_ground = not foot_animator.is_on_ground
