extends Node3D

class_name PathPointVisualizer

@export var vehicle: Vehicle4

func _process(delta: float) -> void:
	if !get_parent().visible:
		return
	
	if vehicle == vehicle.world.player_vehicle:
		visible = false
	
	if vehicle.cpu_logic.curve_point_position == null:
		return
	global_position = vehicle.cpu_logic.curve_point_position
	look_at(global_position + vehicle.cpu_logic.curve_point_forward, -vehicle.gravity.normalized(), true)
