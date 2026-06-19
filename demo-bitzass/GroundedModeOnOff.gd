extends MenuLabel

@export var foot_animator : FootAnimator

func _ready() -> void:
	foot_animator.on_ground_set.connect(func():
		text = "Grounded" if foot_animator.is_on_ground else "On air"
		)

func select():
	foot_animator.is_on_ground = not foot_animator.is_on_ground
