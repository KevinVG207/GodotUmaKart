extends SlidingItem

class_name ThrownGreenBean

func _ready() -> void:
	super()
	%AnimationPlayer.speed_scale = 1.0 if randf() < 0.5 else -1.0
