extends Decal

@export var vehicle: Vehicle4

func _process(delta: float) -> void:
	var target := global_position + vehicle.basis.z
	look_at(target, -vehicle.gravity, true)
