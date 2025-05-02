extends DraggedItem

class_name DraggedJuice

func _on_body_entered(body: Variant) -> void:
	if body == self:
		return
	
	if body is Vehicle4:
		var vehicle := body as Vehicle4
		if damage_type != Vehicle4.DamageType.NONE and vehicle != owned_by and !vehicle.is_network:
			vehicle.damage(damage_type)
			destroy()
		return
