extends Node3D

class_name NetworkTruthVisualizer

@export var vehicle: Vehicle4

func _process(delta: float) -> void:
	if !get_parent().visible:
		return
	
	if !vehicle.is_network:
		return
	
	if !vehicle.network.prev_transform:
		return
	global_transform = vehicle.network.prev_transform
