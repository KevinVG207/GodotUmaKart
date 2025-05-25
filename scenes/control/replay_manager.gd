extends Node

class_name ReplayManager

class ReplayData:
	var course_name: String = ""
	var states: Array[RaceState] = []
	var idx: int = 0
	var finish_times: Dictionary[int, float] = {}  # player_id: time
	
	func to_dict() -> Dictionary:
		var s_array := []
		for state in states:
			s_array.append(state.to_dict())
		
		return {
			"course_name": course_name,
			# "vehicles": v_array,
			"states": s_array,
			"finish_times": finish_times
		}
	
	static func from_dict(data: Dictionary) -> ReplayData:
		var out := ReplayData.new()

		if "course_name" not in data:
			print("ERR: Could not load replay data, course_name not found")
			return null
		
		out.course_name = data["course_name"]

		if "states" not in data:
			print("ERR: Could not load replay data, states not found")
			return null
		
		var s_array: Array = data["states"]
		for state in s_array:
			var race_state := RaceState.from_dict(state)
			if race_state == null:
				print("ERR: Could not parse race state")
				return null
			out.states.append(race_state)
		
		if "finish_times" not in data:
			print("ERR: Could not load replay data, finish_times not found")
			return null
		
		out.finish_times = data["finish_times"]

		return out

# class VehicleSpawnData:
# 	var user_id: String
# 	var new_position: Vector3
# 	var look_dir: Vector3
# 	var up_dir: Vector3
	
# 	func to_dict() -> Dictionary:
# 		return {
# 			"user_id": user_id,
# 			"new_position": Util.to_array(new_position),
# 			"look_dir": Util.to_array(look_dir),
# 			"up_dir": Util.to_array(up_dir)
# 		}

class RaceState:
	var vehicle_states: Array[VehicleState] = []
	var item_states: Array[ItemState] = []
	var items_to_spawn: Array[DomainRace.ItemSpawnWrapper] = []
	var time: float
	
	func to_dict() -> Dictionary:
		var v_dict := []
		for state in vehicle_states:
			v_dict.append(state.to_dict())
		
		var i_dict := []
		for state in item_states:
			i_dict.append(state.to_dict())
			
		var out := {}
		
		if v_dict:
			out.vehicle_states = v_dict
		
		if i_dict:
			out.item_states = i_dict
		
		if items_to_spawn:
			out.items_to_spawn = items_to_spawn
		
		out.time = time
		
		return out
	
	static func from_dict(data: Dictionary) -> RaceState:
		var out := RaceState.new()
		
		if "vehicle_states" in data:
			var v_array: Array = data.vehicle_states
			for state: Dictionary in v_array:
				var vehicle_state := VehicleState.from_dict(state)
				if vehicle_state == null:
					print("ERR: Could not parse vehicle state")
					return null
				out.vehicle_states.append(vehicle_state)
		
		if "item_states" in data:
			var i_array: Array = data.item_states
			for state: Dictionary in i_array:
				var item_state := ItemState.from_dict(state)
				if item_state == null:
					print("ERR: Could not parse item state")
					return null
				out.item_states.append(item_state)
		
		if "items_to_spawn" in data:
			out.items_to_spawn = data.items_to_spawn
		
		if "time" not in data:
			print("ERR: Could not load replay data, time not found")
			return null
		
		return out

class VehicleState:
	var id: int
	var position: Vector3
	var rotation: Quaternion
	var input: Vehicle4.VehicleInput
	
	func to_dict() -> Dictionary:
		var out := {}

		out.id = id
		out.position = position  # Util.to_array(position)
		out.rotation = rotation  # Util.quat_to_array(rotation)
		out.input = input.to_dict()

		return out
	
	static func from_dict(data: Dictionary) -> VehicleState:
		var out := VehicleState.new()

		if "id" not in data:
			print("ERR: Could not load replay data, id not found")
			return null
		out.id = data.id

		if "position" not in data:
			print("ERR: Could not load replay data, position not found")
			return null
		out.position = data.position


		if "rotation" not in data:
			print("ERR: Could not load replay data, rotation not found")
			return null
		out.rotation = data.rotation

		if "input" not in data:
			print("ERR: Could not load replay data, input not found")
			return null
		out.input = Vehicle4.VehicleInput.from_dict(data.input)

		return out

class ItemState:
	var key: String
	
	func to_dict() -> Dictionary:
		return {
			"key": key
		}
	
	static func from_dict(data: Dictionary) -> ItemState:
		var out := ItemState.new()

		if "key" not in data:
			print("ERR: Could not load replay data, key not found")
			return null
		out.key = data.key

		return out

var write_replay: ReplayData = null
var loaded_replay: ReplayData = null
var loaded_replay_vehicles: Dictionary = {}
var replay_thread: Thread = null
var replay_thread_semaphore: Semaphore = null
var replay_thread_mutex: Mutex = null

# var vehicle_spawn_data: Array[VehicleSpawnData] = []
var item_spawn_data: Array[DomainRace.ItemSpawnWrapper] = []

func _ready() -> void:
	replay_thread_mutex = Mutex.new()
	replay_thread_semaphore = Semaphore.new()
	replay_thread = Thread.new()
	replay_thread.start(_replay_thread_loop)

# func spawn_vehicle(user_id: String, new_position: Vector3, look_dir: Vector3, up_dir: Vector3) -> void:
# 	var data := VehicleSpawnData.new()
# 	data.user_id = user_id
# 	data.new_position = new_position
# 	data.look_dir = look_dir
# 	data.up_dir = up_dir
# 	vehicle_spawn_data.append(data)

func spawn_item(data: DomainRace.ItemSpawnWrapper) -> void:
	item_spawn_data.append(data)

func get_course_name_from_world(world: RaceBase) -> String:
	return Util.get_race_course_name_from_path(world.scene_file_path)

func setup_new_replay(world: RaceBase) -> void:
	var course_name := get_course_name_from_world(world)
	write_replay = ReplayData.new()
	write_replay.course_name = course_name
	return

func save_state(world: RaceBase) -> void:
	if write_replay == null:
		print("ERR: Attempted to save state to replay, but no replay is set up!")
		return
	var state := RaceState.new()
	state.time = world.get_timer_seconds()
	state.items_to_spawn = item_spawn_data
	item_spawn_data = []
	
	for id: int in world.players_dict:
		state.vehicle_states.append(make_vehicle_state(id, world))
	
	for key: String in world.physical_items:
		state.item_states.append(make_item_state(key, world))
	
	replay_thread_mutex.lock()
	write_replay.states.append(state)
	replay_thread_mutex.unlock()
	return

func make_vehicle_state(id: int, world: RaceBase) -> VehicleState:
	var state := VehicleState.new()
	
	var player: Vehicle4 = world.players_dict[id]

	state.id = id
	state.position = player.global_position
	state.rotation = player.global_transform.basis.get_rotation_quaternion()
	state.input = player.input
	
	return state

func make_item_state(key: String, world: RaceBase) -> ItemState:
	var state := ItemState.new()
	
	state.key = key
	
	return state

func set_finish_time(id: int, time: float) -> void:
	if write_replay == null:
		print("ERR: Attempted to set finish time, but no replay is set up!")
		return
	write_replay.finish_times[id] = time
	return

func save_replay() -> void:
	print("SAVE REPLAY")
	if write_replay == null:
		print("ERR: Attempted to save replay, but no replay is set up!")
		return

	print("Saving replay")
	replay_thread_semaphore.post()
	return

func wait_for_replay_thread() -> void:
	print("Waiting for replay save thread")
	replay_thread_semaphore.post()
	replay_thread.wait_to_finish()
	print("Replay save thread is finished")

func load_replay(path: String, world: RaceBase) -> int:
	loaded_replay = null

	if !FileAccess.file_exists(path):
		print("ERR: Could not load replay, file does not exist ", path)
		return ERR_FILE_NOT_FOUND

	var raw_data: Variant = Util.load_var(path)

	if raw_data == null:
		print("ERR: Could not load replay data from ", path)
		return ERR_FILE_CORRUPT
	
	if raw_data is not Dictionary:
		print("ERR: Loaded replay data is not of type Dictionary ", path)
		return ERR_INVALID_DATA
	
	var data := ReplayData.from_dict(raw_data)
	
	if data.course_name != get_course_name_from_world(world):
		print("ERR: Loaded replay data is for a different course ", data.course_name, " != ", get_course_name_from_world(world))
		return ERR_INVALID_DATA

	loaded_replay = data
	Debug.print("Loaded replay with finish times:")
	for id: int in loaded_replay.finish_times:
		Debug.print([id, loaded_replay.finish_times[id]])

	return OK

func advance_loaded_state(world: RaceBase) -> void:
	if loaded_replay == null:
		# Maybe this is not an error, we might just call this every frame regardless.
		return
	
	if loaded_replay.idx >= loaded_replay.states.size():
		return
	
	var state := loaded_replay.states[loaded_replay.idx] as RaceState

	for vehicle_state in state.vehicle_states:
		if !vehicle_state.id in loaded_replay_vehicles:
			make_new_vehicle(vehicle_state.id, world)
		
		var vehicle := loaded_replay_vehicles[vehicle_state.id] as Vehicle4

		vehicle.global_position = vehicle_state.position
		vehicle.global_transform.basis = Basis(vehicle_state.rotation)
		vehicle.input = vehicle_state.input

	loaded_replay.idx += 1
	return

func make_new_vehicle(id: int, world: RaceBase) -> void:
	var vehicle := world.player_scene.instantiate() as Vehicle4
	vehicle.world = world
	vehicle.setup_replay()
	world.replay_vehicles.add_child(vehicle)
	loaded_replay_vehicles[id] = vehicle

func _exit_tree() -> void:
	wait_for_replay_thread()
	return

func _replay_thread_loop() -> void:
	replay_thread_semaphore.wait()
	if !write_replay:
		return
	
	var t0 := Time.get_ticks_msec()
	replay_thread_mutex.lock()
	var data := write_replay.to_dict()
	var course_name := write_replay.course_name
	replay_thread_mutex.unlock()
	var t1 := Time.get_ticks_msec()

	var file: String = str(round(Time.get_unix_time_from_system()))
	var dir: String = "user://replays/" + course_name
	var path := dir + "/" + file + ".sav"
	DirAccess.make_dir_recursive_absolute(dir)

	# var t2 := Time.get_ticks_msec()
	# Util.save_string_zip(path, JSON.stringify(data))
	var t3 := Time.get_ticks_msec()
	Util.save_var(path, data)
	var t4 := Time.get_ticks_msec()
	# Util.save_string(path + "3", JSON.stringify(data))
	# var t5 := Time.get_ticks_msec()

	replay_thread_mutex.lock()
	write_replay = null
	replay_thread_mutex.unlock()
	print("Replay finished saving")
	print("ms to serialize: ", t1 - t0)
	# print("ms to save json zip: ", t3 - t2)
	# print("ms to save json: ", t5 - t4)
	print("ms to save dict var: ", t4 - t3)
