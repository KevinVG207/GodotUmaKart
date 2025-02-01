extends Node3D

class_name GravityVisualizer

@export var vehicle: Vehicle4

func _process(delta: float) -> void:
	if !vehicle.is_player:
		visible = false
		return
	visible = true

	if vehicle.gravity == Vector3.ZERO:
		return
	
	look_at(global_position + vehicle.gravity, vehicle.transform.basis.z, true)
