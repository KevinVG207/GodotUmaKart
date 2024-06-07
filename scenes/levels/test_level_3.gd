extends Node3D

var checkpoints: Array = []
var key_checkpoints: Dictionary = {}
var players: Array = []
var players_dict: Dictionary = {}
var mutex: Mutex
var update_vehicles_semaphore: Semaphore = null
var frames_between_update: int = 15
var update_wait_frames: int = 0
var should_exit: bool = false
var update_thread: Thread
var player_vehicle: Vehicle3 = null
@onready var vehicles_node: Node3D = $Vehicles

@export var player_scene: PackedScene


func _ready():
	#$MultiplayerSpawner.spawn_function = _spawn_function
	mutex = Mutex.new()
	update_vehicles_semaphore = Semaphore.new()
	update_thread = Thread.new()
	setup()
	update_thread.start(update_vehicles)

func setup():
	Debug.print("SETUP")
	
	checkpoints = []
	key_checkpoints = {}
	players = []
	
	# Setup checkpoints
	for checkpoint: Checkpoint in $Checkpoints.get_children():
		checkpoints.append(checkpoint)
		if checkpoint.is_key:
			key_checkpoints[checkpoint] = key_checkpoints.size()

	var i = 0
	for vehicle: Vehicle3 in $Vehicles.get_children():
		vehicle.rank = i
		players.append(vehicle)
		vehicle.check_idx = len(checkpoints)-1
		vehicle.check_key_idx = key_checkpoints.size()-1
		i += 1
		if vehicle.is_player:
			player_vehicle = vehicle
			$PlayerCamera.target = vehicle

func _physics_process(_delta):
	update_wait_frames += 1
	if update_wait_frames > frames_between_update:
		update_wait_frames = 0
		update_vehicles_semaphore.post()
	
	# Player checkpoints
	for player: Vehicle3 in players:
		update_checkpoint(player)
		update_ranks()

func _update_vehicles():
	# Send current player vehicle data
	if player_vehicle:
		player_vehicle.call_deferred("upload_data")
	else:
		return
	
	mutex.lock()
	var player_id = Network.unique_id
	mutex.unlock()
	if player_id.is_empty():
		return
	
	if not player_id in players_dict:
		players_dict[player_id] = player_vehicle
	
	mutex.lock()
	var cur_vehicle_states = Network.cur_vehicle_states.duplicate(true)
	if cur_vehicle_states:
		Network.cur_vehicle_states.clear()
	mutex.unlock()
	
	if cur_vehicle_states:
		call_deferred("update_vehicle_states", cur_vehicle_states, player_id)

func update_vehicles():
	while true:
		update_vehicles_semaphore.wait()
		
		mutex.lock()
		var _should_exit = should_exit
		mutex.unlock()
		
		if _should_exit:
			break
		
		_update_vehicles()

func update_ranks():
	var ranks = []
	var ranks_vehicles = []
	for vehicle: Vehicle3 in players:
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


#func _on_multiplayer_spawner_spawned(node):
	#setup()


#func _on_host_button_pressed():
	#pass
	#Network.send_data(Time.get_unix_time_from_system())
	#Network.peer.create_server(135)
	#multiplayer.multiplayer_peer = Network.peer
	#multiplayer.peer_connected.connect(_add_player)
	#_add_player()

func _add_player(id=1):
	$MultiplayerSpawner.spawn({'peer_id': id, 'initial_transform': $SpawnPosition.transform})
	#var player = player_scene.instantiate() as Vehicle3
	#player.transform = $SpawnPosition.transform
	#player.name = str(id)
	#$Vehicles.call_deferred("add_child", player)


#func _on_join_button_pressed():
	#Network.peer.create_client("127.0.0.1", 135)
	#multiplayer.multiplayer_peer = Network.peer
	
#func _on_join_button_pressed():
	#Network.websocket_connect()
	#Network.send_data("Hello")
	
func _spawn_function(data: Variant) -> Node:
	var scene: Vehicle3 = player_scene.instantiate() as Vehicle3
	scene.peer_id = data.peer_id
	scene.initial_transform = data.initial_transform
	return scene

func update_vehicle_states(cur_vehicle_states: Dictionary, player_id: String):
	# Get rid of expired vehicles
	var should_setup = false

	for vehicle_key: String in players_dict.keys():
		if not vehicle_key in cur_vehicle_states:
			var idx = players.find(players_dict[vehicle_key])
			mutex.lock()
			players.remove_at(idx)
			players_dict[vehicle_key].queue_free()
			players_dict.erase(vehicle_key)
			should_setup = true
			mutex.unlock()
	
	for vehicle_key: String in cur_vehicle_states:
		if vehicle_key == player_id:
			continue
		
		if not cur_vehicle_states[vehicle_key]:
			continue
		
		if not vehicle_key in players_dict:
			should_setup = true
			var new_player = player_scene.instantiate() as Vehicle3
			new_player.is_player = false
			new_player.is_cpu = false
			mutex.lock()
			vehicles_node.add_child(new_player)
			players_dict[vehicle_key] = new_player
			players.append(new_player)
			mutex.unlock()
		
		players_dict[vehicle_key].call_deferred("apply_state", cur_vehicle_states[vehicle_key].duplicate(true))

	if should_setup:
		call_deferred("setup")
