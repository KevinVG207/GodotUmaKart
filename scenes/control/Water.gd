extends Area3D

func _on_body_entered(body):
	if "water_entered" in body:
		body.water_entered(self)



func _on_body_exited(body):
	if "water_exited" in body:
		body.water_exited(self)
