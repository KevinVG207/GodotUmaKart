extends Node3D

func get_vehicle_accel(max_speed: float, cur_speed: float, initial_accel: float, exponent: float) -> float:
	var speed_ratio = clamp(cur_speed / max_speed, 0, 1)
	return max(-initial_accel * speed_ratio ** exponent + initial_accel, 0)

func sum(array: Array):
	if not array:
		return null
	
	var out = array[0]
	
	if len(array) == 1:
		return out
	
	for ele in array.slice(1):
		out += ele
	return out

func raycast_for_group(obj: Node3D, start_pos: Vector3, end_pos: Vector3, group: String, ignore_array: Array = []):
	var space_state = obj.get_world_3d().direct_space_state
	var out: Dictionary = {}
	while true:
		var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start_pos, end_pos, 0xFFFFFFFF, ignore_array))
		# Debug.print(result)
		if not result:
			break
		var collider = result["collider"] as Node
		if collider.is_in_group(group):
			out = result
			result["start"] = start_pos
			result["end"] = end_pos
			result["distance"] = result["position"].distance_to(start_pos)
			break
		ignore_array.append(collider)
	ignore_array.clear()
	return out
