extends Area3D

class_name FallBoundary

func _enter_tree() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(10, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(3, true)

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	if body is Vehicle4 and !body.is_network:
		body.respawn()
