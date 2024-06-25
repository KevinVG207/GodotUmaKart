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

func raycast_for_group(obj: Node3D, start_pos: Vector3, end_pos: Vector3, group: String, ignore_array: Array = [], collision_mask=0xFFFFFFFF):
	var space_state = obj.get_world_3d().direct_space_state
	var out: Dictionary = {}
	while true:
		var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start_pos, end_pos, collision_mask, ignore_array))
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

func to_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func to_vector3(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])

func sec_to_ticks(sec: float) -> int:
	# Turns seconds into physics ticks
	return int(sec * Engine.physics_ticks_per_second)

func ticks_to_sec(ticks: int) -> float:
	# Turns physics ticks into seconds
	return float(ticks) / Engine.physics_ticks_per_second

func format_time_minutes(seconds: float) -> String:
	var _seconds = ceil(seconds)
	var minutes = floor(_seconds / 60)
	_seconds -= minutes * 60
	return str(minutes).pad_zeros(1) + ":" + str(_seconds).pad_zeros(2)

func format_time_ms(seconds: float) -> String:
	var minutes = floor(seconds / 60)
	var _seconds = floor(seconds - minutes * 60)
	var ms = floor((seconds - minutes * 60 - _seconds) * 1000)
	return str(minutes).pad_zeros(1) + ":" + str(_seconds).pad_zeros(2) + "." + str(ms).pad_zeros(3)

func get_race_courses() -> Array:
	# All race courses are stored as scenes/race/COURSE_NAME/COURSE_NAME.tscn
	var race_dir = DirAccess.open("res://scenes/levels/race")
	var dirs = race_dir.get_directories()
	var courses = []
	for dir in dirs:
		var course_name: String = dir.split("/")[-1]
		# Ignore test courses
		if course_name[0] == "_":
			continue
		courses.append(course_name)
	return courses

func get_race_course_path(course_name: String):
	return "res://scenes/levels/race/" + course_name + "/" + course_name + ".tscn"

func get_vehicles() -> Array:
	# All vehicles are stored as scenes/vehicles/list/NAME.tscn
	var dir = DirAccess.open("res://scenes/vehicles/list")
	var files = dir.get_files()
	var vehicles = []
	for file in files:
		var key: String = file.split("/")[-1].rsplit(".", true, 1)[0]
		vehicles.append(key)
	return vehicles

func get_vehicle_texture(vehicle_name: String) -> CompressedTexture2D:
	return load("res://assets/vehicles/" + vehicle_name + ".png")

func get_vehicle_scene_path(vehicle_name: String):
	return "res://scenes/vehicles/list/" + vehicle_name + ".tscn"

func ticks_to_time_with_ping(ticks_left: int, tick_rate: int, ping_ms: int) -> float:
	# Debug.print(["Ping: ", ping_ms])
	return (float(ticks_left) / tick_rate) - (ping_ms / 1000.0)

func make_ordinal(n: int) -> String:
	var suffix = ""
	if n % 100 in [11, 12, 13]:
		suffix = "th"
	else:
		match n % 10:
			1:
				suffix = "st"
			2:
				suffix = "nd"
			3:
				suffix = "rd"
			_:
				suffix = "th"
	return str(n) + suffix

func align_with_y(xform: Transform3D, new_y: Vector3):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

func get_path_point_ahead_of_player(world: RaceBase, player: Vehicle3):
	var points: Array = world.get_node("EnemyPathPoints").find_children("*", "EnemyPath")
	var plane_pos: Vector3 = player.get_node("Front").global_position
	var plane_normal: Vector3 = player.transform.basis.x
	
	var filtered_point: EnemyPath
	var filtered_distance = 1000000000
	
	for point: EnemyPath in points:
		var dist_ahead: float = plane_normal.dot(point.global_position - plane_pos)
		if dist_ahead >= 0:
			var dist: float = player.global_position.distance_to(point.global_position)
			if dist < filtered_distance:
				filtered_distance = dist
				filtered_point = point
	
	if filtered_point:
		return filtered_point
	
	# Fallback to nearest
	for point: EnemyPath in points:
		var dist: float = player.global_position.distance_to(point.global_position)
		if dist < filtered_distance:
			filtered_distance = dist
			filtered_point = filtered_point
	
	return filtered_point
