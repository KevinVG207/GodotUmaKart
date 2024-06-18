extends Area3D


func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	print(body)
	if body is Vehicle3:
		body.respawn()
