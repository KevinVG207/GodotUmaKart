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

@export var start_offset_z: float = 4.0
@export var start_offset_x: float = 2.0

@onready var vehicles_node: Node3D = $Vehicles

@export var player_scene: PackedScene

class raceOp:
	const SERVER_UPDATE_VEHICLE_STATE = 1
	const CLIENT_UPDATE_VEHICLE_STATE = 2

const STATE_DISCONNECT = -1
const STATE_INITIAL = 0
const STATE_JOINING = 1
const STATE_WAIT_FOR_PING = 2
const STATE_READY_FOR_START = 10
const STATE_WAIT_FOR_START = 11
const STATE_RACE = 12

var state = STATE_INITIAL

func _ready():
	checkpoints = []
	key_checkpoints = {}
	
	# Setup checkpoints
	for checkpoint: Checkpoint in $Checkpoints.get_children():
		checkpoints.append(checkpoint)
		if checkpoint.is_key:
			key_checkpoints[checkpoint] = key_checkpoints.size()


func change_state(new_state: int, state_func: Callable = Callable()):
	state = new_state
	state_func.call()

func _physics_process(_delta):
	match state:
		STATE_INITIAL:
			change_state(STATE_JOINING, join)
		STATE_READY_FOR_START:
			pass
		_:
			pass
	
	#update_wait_frames += 1
	#if update_wait_frames > frames_between_update:
		#update_wait_frames = 0
		#if player_vehicle:
			#player_vehicle.call_deferred("upload_data")
	#
	## Player checkpoints
	#for vehicle: Vehicle3 in $Vehicles.get_children():
		#update_checkpoint(vehicle)
		#update_ranks()

func _add_vehicle(user_id: String, new_position: Vector3, new_rotation: Vector3):
	var new_vehicle = player_scene.instantiate() as Vehicle3
	new_vehicle.global_position = new_position
	new_vehicle.global_rotation = new_rotation
	new_vehicle.is_player = false
	new_vehicle.is_cpu = false
	new_vehicle.is_network = true
	vehicles_node.add_child(new_vehicle)
	players_dict[user_id] = new_vehicle
	if user_id == Network.session.user_id:
		new_vehicle.is_player = true
		player_user_id = user_id
		player_vehicle = new_vehicle
		$PlayerCamera.target = new_vehicle


func setup_vehicles():
	var start_checkpoint = checkpoints[0] as Checkpoint
	var start_position = start_checkpoint.global_position
	var start_direction = -start_checkpoint.transform.basis.z
	var side_direction = start_checkpoint.transform.basis.x
	var start_rotation = start_checkpoint.global_rotation

	# Rotate start rotation 90 degrees along checkpoint's y axis
	start_rotation = start_rotation.rotated(start_checkpoint.transform.basis.y, PI/2)

	for i in range(starting_order.size()):
		var user_id = starting_order[i]
		
		var side_multi = 1
		if i % 2 == 1:
			side_multi = -1

		var cur_pos = start_position + start_offset_z * i * start_direction + side_multi * start_offset_x * side_direction

		_add_vehicle(user_id, cur_pos, start_rotation)

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
	
	state = STATE_WAIT_FOR_PING
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
	
	players_dict[user_id].call_deferred("apply_state", vehicle_state)



func _on_match_state(match_state : NakamaRTAPI.MatchData):
	var data: Dictionary = JSON.parse_string(match_state.data)
	match match_state.op_code:
		raceOp.SERVER_UPDATE_VEHICLE_STATE:
			update_vehicle_state(data, match_state.presence.user_id)
		_:
			print("Unknown match state op code: ", match_state.op_code)
