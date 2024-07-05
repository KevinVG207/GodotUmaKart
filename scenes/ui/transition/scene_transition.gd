extends Control

class_name SceneTransition

signal middle_reached

@onready var ani: AnimationPlayer = $AnimationPlayer

func _process(delta):
	# Scale to fit screen.
	# Get cur sizes
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	# Scale to fit width.
	var scale_factor: float = viewport_size.x / size.x
	
	# Scale to fit height.
	if size.y * scale_factor < viewport_size.y:
		scale_factor = viewport_size.y / size.y
	
	scale.x = scale_factor
	scale.y = scale_factor

func _on_middle_reached(_anim_name):
	ani.animation_finished.disconnect(_on_middle_reached)
	middle_reached.emit()

func start():
	ani.play("begin")
	ani.animation_finished.connect(_on_middle_reached)

func end():
	ani.play("end")
	ani.animation_finished.connect(_cleanup)

func _cleanup(_anim_name):
	queue_free()
