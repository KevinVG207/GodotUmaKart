extends Area3D

class_name WaterArea

func _on_body_entered(body: Node) -> void:
	if "water_entered" in body:
		Debug.print(["Water entered: ", body])
		body.water_entered(self)



func _on_body_exited(body: Node) -> void:
	if "water_exited" in body:
		body.water_exited(self)
