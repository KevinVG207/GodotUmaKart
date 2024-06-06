extends Node3D


var checkpoints: Array = []
var key_checkpoints: Dictionary = {}
var players: Array = []

@export var player_scene: PackedScene


func _ready():
	#$MultiplayerSpawner.spawn_function = _spawn_function
	setup()

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
			$PlayerCamera.target = vehicle

func _process(_delta):
	if Network.should_setup:
		Network.should_setup = false
		setup()
	
	# Player checkpoints
	for player: Vehicle3 in players:
		update_checkpoint(player)
		update_ranks()


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


func _on_host_button_pressed():
	Network.send_data("Hello")
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
	
func _on_join_button_pressed():
	Network.websocket_connect()
	#Network.send_data("Hello")
	
func _spawn_function(data: Variant) -> Node:
	var scene: Vehicle3 = player_scene.instantiate() as Vehicle3
	scene.peer_id = data.peer_id
	scene.initial_transform = data.initial_transform
	return scene
