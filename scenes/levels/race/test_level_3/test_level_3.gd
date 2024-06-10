extends Node3D

class_name LevelBase

var checkpoints: Array = []
var key_checkpoints: Dictionary = {}
var players_dict: Dictionary = {}
var frames_between_update: int = 15
var update_wait_frames: int = 0
var should_exit: bool = false
var update_thread: Thread
var player_vehicle: Vehicle3 = null
var player_user_id: String = ""
var removed_player_ids: Array = []
var starting_order: Array = []

@export var start_offset_z: float = 2
@export var start_offset_x: float = 3

@onready var vehicles_node: Node3D = $Vehicles

@export var player_scene: PackedScene

class raceOp:
	const SERVER_UPDATE_VEHICLE_STATE = 1
	const CLIENT_UPDATE_VEHICLE_STATE = 2
	const SERVER_PING = 3
	const CLIENT_VOTE = 4
	const SERVER_PING_DATA = 5
	const SERVER_RACE_START = 6
	const CLIENT_READY = 7

const STATE_DISCONNECT = -1
const STATE_INITIAL = 0
const STATE_JOINING = 1
const STATE_READY_FOR_START = 2
const STATE_WAIT_FOR_START = 3
const STATE_RACE = 4

const UPDATE_STATES = [
	STATE_WAIT_FOR_START,
	STATE_RACE
]

var state = STATE_INITIAL

func _ready():
	UI.show_race_ui()

	checkpoints = []
	key_checkpoints = {}
	
	# Setup checkpoints
	for checkpoint: Checkpoint in $Checkpoints.get_children():
		checkpoints.append(checkpoint)
		if checkpoint.is_key:
			key_checkpoints[checkpoint] = key_checkpoints.size()


func _process(_delta):
	if not $StartTimer.is_stopped():
		UI.update_countdown(str(ceil($StartTimer.time_left)))
	else:
		UI.update_countdown("")


func change_state(new_state: int, state_func: Callable = Callable()):
	state = new_state
	state_func.call()

func _physics_process(_delta):
	match state:
		STATE_INITIAL:
			change_state(STATE_JOINING, join)
		_:
			pass
	
	if state in UPDATE_STATES:
		update_wait_frames += 1
		if update_wait_frames > frames_between_update:
			update_wait_frames = 0
			if player_vehicle:
				var vehicle_data: Dictionary = player_vehicle.get_state()
				Network.send_match_state(raceOp.CLIENT_UPDATE_VEHICLE_STATE, vehicle_data)
				#player_vehicle.call_deferred("upload_data")
		
		# Player checkpoints
		for vehicle: Vehicle3 in $Vehicles.get_children():
			update_checkpoint(vehicle)
			update_ranks()

func _add_vehicle(user_id: String, new_position: Vector3, look_dir: Vector3, up_dir: Vector3):
	var new_vehicle = player_scene.instantiate() as Vehicle3
	players_dict[user_id] = new_vehicle
	vehicles_node.add_child(new_vehicle)
	new_vehicle.teleport(new_position, look_dir, up_dir)
	new_vehicle.axis_lock()
	new_vehicle.is_player = false
	new_vehicle.is_cpu = false
	new_vehicle.is_network = true
	if user_id == Network.session.user_id:
		new_vehicle.is_player = true
		new_vehicle.is_network = false
		player_user_id = user_id
		player_vehicle = new_vehicle
		$PlayerCamera.target = new_vehicle


func setup_vehicles():
	var start_checkpoint = checkpoints[0] as Checkpoint
	var start_position = start_checkpoint.global_position
	var start_direction = -start_checkpoint.transform.basis.z
	var side_direction = start_checkpoint.transform.basis.x
	var up_dir = start_checkpoint.transform.basis.y
	start_position += up_dir * 1.0

	for i in range(starting_order.size()):
		var user_id = starting_order[i]
		
		var side_multi = 1
		if i % 2 == 1:
			side_multi = -1

		var cur_pos = start_position + start_offset_z * (i + 3) * start_direction + side_multi * start_offset_x * side_direction

		_add_vehicle(user_id, cur_pos, -start_direction, up_dir)

func join():
	starting_order = Network.next_match_data.startingIds
	setup_vehicles()

	var res: bool = await Network.join_match(Network.ready_match)
	
	Network.socket.received_match_state.connect(_on_match_state)

	if not res or not Network.cur_match:
		# Disconnect functions
		Network.socket.received_match_state.disconnect(_on_match_state)

		state = STATE_DISCONNECT
		return
	
	state = STATE_WAIT_FOR_START
	return


func update_ranks():
	var ranks = []
	var ranks_vehicles = []
	for vehicle: Vehicle3 in $Vehicles.get_children():
		var cur_progress = 10000 * vehicle.lap + vehicle.check_idx + vehicle.check_progress
		if not ranks:
			ranks.append(cur_progress)
			ranks_vehicles.append(vehicle)
			continue

		var stop = false
		for i in range(ranks.size()):
			if cur_progress > ranks[i]:
				ranks.insert(i, cur_progress)
				ranks_vehicles.insert(i, vehicle)
				stop = true
				break

		if stop:
			continue

		ranks.append(cur_progress)
		ranks_vehicles.append(vehicle)


	for i in range(ranks.size()):
		ranks_vehicles[i].rank = i
	
	UI.update_ranks(ranks_vehicles)


func update_checkpoint(player: Vehicle3):
	while true:
		var next_idx = player.check_idx+1 % len(checkpoints)
		if next_idx >= len(checkpoints):
			next_idx -= len(checkpoints)
		if dist_to_checkpoint(player, next_idx) > 0:
			var next_checkpoint: Checkpoint = checkpoints[next_idx]
			
			# Don't advance to next key checkpoint if the previous key checkpoint wasn't reached
			if next_checkpoint.is_key:
				var cur_key_idx = key_checkpoints[next_checkpoint]
				var prev_key_idx = cur_key_idx - 1
				if prev_key_idx < 0:
					prev_key_idx = key_checkpoints.size()-1
				if prev_key_idx != player.check_key_idx and player.check_key_idx != cur_key_idx:
					break
				player.check_key_idx = cur_key_idx

			player.check_idx = next_idx
			if next_idx == 0:
				# Crossed the finish line
				player.lap += 1
		else:
			break
	
	while true:
		var prev_idx = (player.check_idx - 1) % len(checkpoints)
		if prev_idx < 0:
			prev_idx = len(checkpoints) + prev_idx
		if dist_to_checkpoint(player, player.check_idx) < 0:
			var prev_checkpoint: Checkpoint = checkpoints[prev_idx]
			if prev_checkpoint.is_key:
				var cur_key = player.check_key_idx
				
				#Debug.print([cur_key, key_checkpoints[prev_checkpoint]])
				var prev_key = key_checkpoints[prev_checkpoint]
				var subtract = 0
				if prev_key == 0:
					subtract = key_checkpoints.size()
					prev_key += subtract
					cur_key += subtract
				elif cur_key == 0:
					cur_key += key_checkpoints.size()
				
				if prev_key != cur_key-1 and prev_key != cur_key:
					break
				
				if prev_key == cur_key-1:
					player.check_key_idx = prev_key - subtract
			
			player.check_idx = prev_idx
			if prev_idx == len(checkpoints)-1:
				player.lap -= 1
		else:
			break
	
	#var cur_checkpoint = checkpoints[player.check_idx]
	#if cur_checkpoint in key_checkpoints:
		#player.check_key_idx = key_checkpoints[cur_checkpoint]

	player.check_progress = progress_in_cur_checkpoint(player)


func dist_to_checkpoint(player: Vehicle3, checkpoint_idx: int) -> float:
	var checkpoint = checkpoints[checkpoint_idx % len(checkpoints)] as Node3D
	return checkpoint.transform.basis.z.dot(player.get_node("Front").global_position - checkpoint.global_position)


func progress_in_cur_checkpoint(player: Vehicle3) -> float:
	var dist_behind: float = abs(dist_to_checkpoint(player, player.check_idx))
	var dist_ahead: float = abs(dist_to_checkpoint(player, player.check_idx+1))
	return dist_behind / (dist_behind + dist_ahead)



func update_vehicle_state(vehicle_state: Dictionary, user_id: String):
	if user_id == player_user_id:
		return
	
	if user_id in removed_player_ids:
		return
	
	if not user_id in players_dict.keys():
		return
	
	players_dict[user_id].apply_state(vehicle_state)
	#players_dict[user_id].call_deferred("apply_state", vehicle_state)


func handle_race_start(data: Dictionary):
	var pings: Dictionary = data.pings as Dictionary
	var ticks_to_start: int = data.ticksToStart as int
	var tick_rate: int = data.tickRate as int

	var seconds_left: float = Util.ticks_to_time_with_ping(ticks_to_start, tick_rate, pings[Network.session.user_id])
	$StartTimer.start(seconds_left)


func _on_match_state(match_state : NakamaRTAPI.MatchData):
	var data: Dictionary = JSON.parse_string(match_state.data)
	match match_state.op_code:
		raceOp.SERVER_UPDATE_VEHICLE_STATE:
			update_vehicle_state(data, match_state.presence.user_id)
		raceOp.SERVER_PING:
			Network.send_match_state(raceOp.SERVER_PING, data)
			pass
		raceOp.SERVER_RACE_START:
			handle_race_start(data)
		_:
			print("Unknown match state op code: ", match_state.op_code)


func _on_start_timer_timeout():
	state = STATE_RACE
	for vehicle: Vehicle3 in $Vehicles.get_children():
		vehicle.axis_unlock()
