extends Node3D

class_name RaceBase

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
var spectate: bool = false
var timer_tick: int = 0

@export var start_offset_z: float = 2
@export var start_offset_x: float = 3

@onready var vehicles_node: Node3D = $Vehicles

var player_scene: PackedScene = preload("res://scenes/vehicles/vehicle_3.tscn")
var rank_panel_scene: PackedScene = preload("res://scenes/ui/rank_panel.tscn")

@export var lap_count: int = 3
var finished = false

var finish_order: Array = []
var rankings_timer: int = 0
var rankings_delay: int = 5
var stop_rankings: bool = false

class raceOp:
	const SERVER_UPDATE_VEHICLE_STATE = 1
	const CLIENT_UPDATE_VEHICLE_STATE = 2
	const SERVER_PING = 3
	const CLIENT_VOTE = 4
	const SERVER_PING_DATA = 5
	const SERVER_RACE_START = 6
	const CLIENT_READY = 7
	const SERVER_RACE_OVER = 8
	const SERVER_CLIENT_DISCONNECT = 9
	const SERVER_ABORT = 10

class finishType:
	const NORMAL = 0
	const TIMEOUT = 1

const STATE_DISCONNECT = -1
const STATE_INITIAL = 0
const STATE_JOINING = 1
const STATE_CAN_READY = 2
const STATE_READY_FOR_START = 3
const STATE_WAIT_FOR_START = 4
const STATE_COUNTDOWN = 5
const STATE_COUNTING_DOWN = 6
const STATE_RACE = 7
const STATE_RACE_OVER = 8
const STATE_READY_FOR_RANKINGS = 9
const STATE_SHOW_RANKINGS = 10
const STATE_JOIN_NEXT = 11
const STATE_JOINING_NEXT = 12
const STATE_SPECTATING = 13

const UPDATE_STATES = [
	STATE_COUNTING_DOWN,
	STATE_RACE
]

var state = STATE_INITIAL

func _ready():
	UI.race_ui.set_max_laps(lap_count)
	UI.race_ui.set_cur_lap(0)
	
	UI.show_race_ui()
	
	UI.race_ui.back_btn.pressed.connect(_on_back_pressed)

	checkpoints = []
	key_checkpoints = {}
	
	# Setup checkpoints
	for checkpoint: Checkpoint in $Checkpoints.get_children():
		checkpoints.append(checkpoint)
		if checkpoint.is_key:
			key_checkpoints[checkpoint] = key_checkpoints.size()


func _process(_delta):
	if not $CountdownTimer.is_stopped():
		UI.race_ui.update_countdown(str(ceil($CountdownTimer.time_left)))
	else:
		UI.race_ui.update_countdown("")
	
	if state == STATE_RACE:
		UI.race_ui.update_time(timer_tick * (1.0/Engine.physics_ticks_per_second))
	
	if state == STATE_SHOW_RANKINGS:
		UI.race_ui.show_back_btn()
		UI.race_ui.update_timeleft($NextRaceTimer.time_left)
	
	if spectate:
		if !$PlayerCamera.target and players_dict:
			$PlayerCamera.target = players_dict.values()[0]
		
		var spectator_index = players_dict.values().find($PlayerCamera.target)
		if spectator_index > -1:
			UI.race_ui.enable_spectating()
			UI.race_ui.set_username(players_dict[players_dict.keys()[spectator_index]].username)
			
			if get_window().has_focus() and Input.is_action_just_pressed("accelerate"):
				$PlayerCamera.instant = true
				spectator_index += 1
				if spectator_index >= players_dict.size():
					spectator_index = 0
			elif get_window().has_focus() and Input.is_action_just_pressed("brake"):
				$PlayerCamera.instant = true
				spectator_index -= 1
				if spectator_index < 0:
					spectator_index = players_dict.size()-1
			
			$PlayerCamera.target = players_dict.values()[spectator_index]


func change_state(new_state: int, state_func: Callable = Callable()):
	state = new_state
	state_func.call()

func _physics_process(_delta):
	match state:
		STATE_INITIAL:
			state = STATE_JOINING
			await join()
		STATE_CAN_READY:
			change_state(STATE_READY_FOR_START, send_ready)
		STATE_COUNTDOWN:
			$CountdownTimer.start(3.0)
			timer_tick = -Engine.physics_ticks_per_second * 3
			state = STATE_COUNTING_DOWN
		STATE_COUNTING_DOWN:
			timer_tick += 1
		STATE_RACE:
			timer_tick += 1
		STATE_RACE_OVER:
			UI.race_ui.race_over()
		STATE_READY_FOR_RANKINGS:
			UI.race_ui.race_over()
			$NextRaceTimer.start(25)
			state = STATE_SHOW_RANKINGS
		STATE_SHOW_RANKINGS:
			UI.race_ui.hide_time()
			handle_rankings()
		STATE_JOIN_NEXT:
			if Global.MODE1 == Global.MODE1_ONLINE:
				change_state(STATE_JOINING_NEXT, join_next)
		_:
			pass
	
	if state in UPDATE_STATES:
		# Player checkpoints
		for vehicle: Vehicle3 in $Vehicles.get_children():
			update_checkpoint(vehicle)
			update_ranks()
			if vehicle == $PlayerCamera.target:
				UI.race_ui.set_cur_lap(vehicle.lap)
		
		if Global.MODE1 == Global.MODE1_ONLINE:
			update_wait_frames += 1
			if update_wait_frames > frames_between_update:
				update_wait_frames = 0
				if player_vehicle:
					var vehicle_data: Dictionary = player_vehicle.get_state()
					Network.send_match_state(raceOp.CLIENT_UPDATE_VEHICLE_STATE, vehicle_data)
					#player_vehicle.call_deferred("upload_data")
		
		check_finished()

func handle_rankings():
	if stop_rankings:
		return
	
	if rankings_timer % rankings_delay == 0:
		var cur_idx: int = rankings_timer / rankings_delay
		
		if cur_idx >= len(finish_order)-1:
			stop_rankings = true
			
		var cur_vehicle: Vehicle3 = players_dict[finish_order[cur_idx]]
		
		var end_position = Vector2(-262, 16 + (40+5)*cur_idx)
		var start_position = end_position
		start_position.x = 800
		var new_panel = rank_panel_scene.instantiate() as RankPanel
		new_panel.get_node("Rank").text = Util.make_ordinal(cur_idx+1)
		new_panel.get_node("PlayerName").text = cur_vehicle.username
		new_panel.position = start_position
		
		if cur_vehicle == player_vehicle:
			new_panel.set_border()
		
		UI.race_ui.get_node("Rankings").add_child(new_panel)
		var tween = create_tween()
		tween.tween_property(new_panel, "position", end_position, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	rankings_timer += 1

func check_finished():
	# Offline mode: All players have finished.
	# Online mode: Wait for server
	if finished:
		return
	
	if Global.MODE1 == Global.MODE1_OFFLINE:
		var is_finished: bool = true
		for vehicle: Vehicle3 in players_dict.values():
			if vehicle.is_player and not vehicle.finished:
				is_finished = false
				break
		finished = is_finished
		if finished:
			state = STATE_RACE_OVER


func _add_vehicle(user_id: String, new_position: Vector3, look_dir: Vector3, up_dir: Vector3):
	var new_vehicle = player_scene.instantiate() as Vehicle3
	players_dict[user_id] = new_vehicle
	vehicles_node.add_child(new_vehicle)
	new_vehicle.teleport(new_position, look_dir, up_dir)
	new_vehicle.axis_lock()
	new_vehicle.is_player = false
	
	match Global.MODE1:
		Global.MODE1_OFFLINE:
			new_vehicle.is_cpu = true
			new_vehicle.is_network = false
			new_vehicle.username = "CPU"
		Global.MODE1_ONLINE:
			new_vehicle.is_cpu = false
			new_vehicle.is_network = true
			new_vehicle.username = "Network Player"
	
	if user_id == player_user_id:
		new_vehicle.is_player = true
		new_vehicle.is_network = false
		player_vehicle = new_vehicle
		$PlayerCamera.target = new_vehicle
		new_vehicle.username = "Player"
		if Global.MODE1 == Global.MODE1_ONLINE:
			new_vehicle.username = Network.session.username

func _remove_vehicle(user_id: String):
	if user_id in players_dict.keys():
		var vehicle = players_dict[user_id]
		if $PlayerCamera.target == vehicle:
			$PlayerCamera.target = null
		vehicle.queue_free()
		players_dict.erase(user_id)
		removed_player_ids.append(user_id)


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

func get_starting_order():
	match Global.MODE1:
		Global.MODE1_ONLINE:
			player_user_id = Network.session.user_id

			if !Network.next_match_data.get('startingIds'):
				spectate = true
				return []

			return Network.next_match_data.startingIds
		Global.MODE1_OFFLINE:
			player_user_id = "Player"
			var player_array = []
			for i in range(11):
				player_array.append("CPU" + str(i))
			player_array.insert(randi_range(0, 11), player_user_id)
			return player_array
	return []

func join():
	starting_order = get_starting_order()
	setup_vehicles()
	Network.next_match_data = {}
	
	if Global.MODE1 == Global.MODE1_OFFLINE:
		state = STATE_COUNTDOWN
		return

	var res: bool = await Network.join_match(Network.ready_match)
	
	Network.socket.received_match_state.connect(_on_match_state)

	if not res or not Network.cur_match:
		# Disconnect functions
		Network.socket.received_match_state.disconnect(_on_match_state)

		state = STATE_DISCONNECT
		return
	
	if spectate:
		state = STATE_SPECTATING
		return

	state = STATE_CAN_READY
	return

func send_ready():
	var res: bool = await Network.send_match_state(raceOp.CLIENT_READY, {})
	
	if not res:
		state = STATE_DISCONNECT
		return
	
	state = STATE_WAIT_FOR_START
	return

func update_ranks():
	var ranks = []
	var ranks_vehicles = []

	var finished_vehicles = []

	for vehicle: Vehicle3 in $Vehicles.get_children():
		if vehicle.finished:
			finished_vehicles.append(vehicle)
			continue

		var check_idx = vehicle.check_idx
		if check_idx < 0:
			check_idx = checkpoints.size() - check_idx - 2
		var cur_progress = 10000 * vehicle.lap + check_idx + vehicle.check_progress
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
	

	finished_vehicles.sort_custom(func(a, b): return a.finish_time < b.finish_time)

	finished_vehicles.append_array(ranks_vehicles)


	for i in range(finished_vehicles.size()):
		finished_vehicles[i].rank = i
	
	UI.update_ranks(finished_vehicles)

	# print("Ranks:")
	# for vehicle: Vehicle3 in finished_vehicles.slice(0, 5):
	# 	print(vehicle.rank, " ", vehicle.finish_time)
	# print("===")


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
				if player.lap > lap_count:
					var time_after_finish = (timer_tick - 1) * (1.0/Engine.physics_ticks_per_second)
					
					var finish_plane_normal: Vector3 = checkpoints[0].transform.basis.z
					var vehicle_vel: Vector3 = player.prev_frame_pre_sim_vel
					var seconds_per_tick = 1.0/Engine.physics_ticks_per_second

					# Determine the ratio of the vehicle_vel to the finish_plane_normal, and determine how much time it had taken to cross the finish line since the last frame
					var final_time = time_after_finish - clamp(dist_to_checkpoint(player, 0) / vehicle_vel.project(finish_plane_normal).length(), 0, seconds_per_tick)
					
					player.set_finished(final_time)
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
		var cur_position: Vector3 = Util.to_vector3(vehicle_state["pos"])
		var cur_rotation: Vector3 = Util.to_vector3(vehicle_state["rot"])

		var look_dir: Vector3 = cur_rotation.normalized()
		var up_dir: Vector3 = Vector3(0, 1, 0)

		_add_vehicle(user_id, cur_position, look_dir, up_dir)
		players_dict[user_id].axis_unlock()
	
	players_dict[user_id].apply_state(vehicle_state)
	#players_dict[user_id].call_deferred("apply_state", vehicle_state)


func handle_race_start(data: Dictionary):
	var pings: Dictionary = data.pings as Dictionary
	var ticks_to_start: int = data.ticksToStart as int
	var tick_rate: int = data.tickRate as int

	var seconds_left: float = Util.ticks_to_time_with_ping(ticks_to_start, tick_rate, pings[Network.session.user_id])
	$StartTimer.start(seconds_left)


func _on_match_state(match_state : NakamaRTAPI.MatchData):
	if Global.randPing:
		await get_tree().create_timer(Global.randPing / 1000.0).timeout
	
	var data: Dictionary = JSON.parse_string(match_state.data)
	match match_state.op_code:
		raceOp.SERVER_UPDATE_VEHICLE_STATE:
			update_vehicle_state(data, match_state.presence.user_id)
		raceOp.SERVER_PING:
			Network.send_match_state(raceOp.SERVER_PING, data)
		raceOp.SERVER_RACE_START:
			handle_race_start(data)
		raceOp.SERVER_CLIENT_DISCONNECT:
			_remove_vehicle(data.userId)
		raceOp.SERVER_RACE_OVER:
			finished = true
			var finish_position: int = data.finishOrder.find(player_user_id)

			Debug.print(["Rank: ", finish_position])

			Network.ready_match = data.matchId
			finish_order = data.finishOrder
			state = STATE_READY_FOR_RANKINGS
		raceOp.SERVER_ABORT:
			get_tree().change_scene_to_file("res://scenes/ui/lobby/lobby.tscn")
		_:
			print("Unknown match state op code: ", match_state.op_code)


func _on_start_timer_timeout():
	state = STATE_COUNTDOWN


func _on_countdown_timer_timeout():
	state = STATE_RACE
	for vehicle: Vehicle3 in $Vehicles.get_children():
		vehicle.axis_unlock()

func join_next():
	UI.reset_race_ui()
	UI.race_ui.visible = false
	Network.socket.received_match_state.disconnect(_on_match_state)
	get_tree().change_scene_to_file("res://scenes/ui/lobby/lobby.tscn")

func _on_back_pressed():
	state = STATE_JOIN_NEXT

func _on_next_race_timer_timeout():
	state = STATE_JOIN_NEXT
