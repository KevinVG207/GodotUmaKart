extends Decal

@export var vehicle: Vehicle4

func _process(delta: float) -> void:
	if vehicle.gravity == Vector3.ZERO:
		visible = false
		return
	visible = true
	var target := global_position + vehicle.basis.z
	look_at(target, -vehicle.gravity, true)
