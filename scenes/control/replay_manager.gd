extends Node

class_name ReplayManager

class ReplayData:
	var course_name: String = ""
	var vehicles: Array[VehicleSpawnData] = []
	var states: Array[RaceState] = []
	var finish_times: Dictionary = {}  # player_id: time
	
	func to_json() -> String:
		var v_array := []
		for data in vehicles:
			v_array.append(data.to_dict())
		
		var s_array := []
		for state in states:
			s_array.append(state.to_dict())
		
		return JSON.stringify({
			"course_name": course_name,
			"vehicles": v_array,
			"states": s_array,
			"finish_times": finish_times
		})

class VehicleSpawnData:
	var user_id: String
	var new_position: Vector3
	var look_dir: Vector3
	var up_dir: Vector3
	
	func to_dict() -> Dictionary:
		return {
			"user_id": user_id,
			"new_position": Util.to_array(new_position),
			"look_dir": Util.to_array(look_dir),
			"up_dir": Util.to_array(up_dir)
		}

class RaceState:
	var vehicle_states: Array[VehicleState] = []
	var item_states: Array[ItemState] = []
	var items_to_spawn: Array[Dictionary] = []
	
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
		
		return out

class VehicleState:
	var id: String = ""
	
	func to_dict() -> Dictionary:
		return {
			"id": id
		}

class ItemState:
	var key: String = ""
	
	func to_dict() -> Dictionary:
		return {
			"key": key
		}

var write_replay: ReplayData = null
var loaded_replay: ReplayData = null
var replay_thread: Thread = null
var replay_thread_semaphore: Semaphore = null
var replay_thread_mutex: Mutex = null

var vehicle_spawn_data: Array[VehicleSpawnData] = []
var item_spawn_data: Array[Dictionary] = []

func _ready() -> void:
	replay_thread_mutex = Mutex.new()
	replay_thread_semaphore = Semaphore.new()
	replay_thread = Thread.new()
	replay_thread.start(_replay_thread_loop)

func spawn_vehicle(user_id: String, new_position: Vector3, look_dir: Vector3, up_dir: Vector3) -> void:
	var data := VehicleSpawnData.new()
	data.user_id = user_id
	data.new_position = new_position
	data.look_dir = look_dir
	data.up_dir = up_dir
	vehicle_spawn_data.append(data)

func spawn_item(data: Dictionary) -> void:
	item_spawn_data.append(data)

func setup_new_replay(world: RaceBase) -> void:
	var course_name := Util.get_race_course_name_from_path(world.scene_file_path)
	write_replay = ReplayData.new()
	write_replay.course_name = course_name
	write_replay.vehicles = vehicle_spawn_data
	vehicle_spawn_data = []
	return

func save_state(world: RaceBase) -> void:
	if write_replay == null:
		print("ERR: Attempted to save state to replay, but no replay is set up!")
		return
	var state := RaceState.new()
	state.items_to_spawn = item_spawn_data
	item_spawn_data = []
	
	for id: String in world.players_dict:
		state.vehicle_states.append(make_vehicle_state(id, world))
	
	for key: String in world.physical_items:
		state.item_states.append(make_item_state(key, world))
	
	replay_thread_mutex.lock()
	write_replay.states.append(state)
	replay_thread_mutex.unlock()
	return

func make_vehicle_state(id: String, world: RaceBase) -> VehicleState:
	var state := VehicleState.new()
	
	state.id = id
	
	return state

func make_item_state(key: String, world: RaceBase) -> ItemState:
	var state := ItemState.new()
	
	state.key = key
	
	return state

func save_replay() -> void:
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

func load_replay() -> void:
	return

func play_state(world: RaceBase) -> void:
	if loaded_replay == null:
		# Maybe this is not an error, we might just call this every frame regardless.
		return
	return

func _exit_tree() -> void:
	wait_for_replay_thread()
	return

func _replay_thread_loop() -> void:
	replay_thread_semaphore.wait()
	replay_thread_mutex.lock()
	var data := write_replay.to_json()
	var course_name := write_replay.course_name
	replay_thread_mutex.unlock()

	var file: String = str(round(Time.get_unix_time_from_system()))
	var dir: String = "user://replays/" + course_name
	var path := dir + "/" + file + ".sav"
	
	DirAccess.make_dir_recursive_absolute(dir)
	Util.save_string_zip(path, data)
	print("Replay finished saving")
