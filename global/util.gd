extends Node

func get_vehicle_accel(max_speed: float, cur_speed: float, initial_accel: float, exponent: float) -> float:
	var speed_ratio = clamp(cur_speed / max_speed, 0, 1)
	return max(-initial_accel * speed_ratio ** exponent + initial_accel, 0)
