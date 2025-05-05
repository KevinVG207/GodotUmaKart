extends Node

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket

# var is_matchmaking: bool = false
# var is_in_match: bool = false

var session_seed: String = str(randi_range(1, 99999999))

var mm_tickets: Array = []
var cur_match: NakamaRTAPI.Match = null
var ready_match: String = ""
var ready_match_type: String = ""
var ready_match_label: Dictionary = {}
var next_match_data: Dictionary = {}

var frames_per_update: int = 6
var frame_count: int = 0

#var escaped_version: String = ProjectSettings.get_setting("application/config/version").replace(".", "-")

func reset():
	if mm_tickets:
		clear_mm_tickets()
	if socket:
		await socket.close()
	socket = null
	if session:
		await client.session_logout_async(session)
	session = null
	client = null
	cur_match = null
	ready_match = ""
	ready_match_type = ""
	ready_match_label = {}
	next_match_data = {}

func is_socket():
	return (socket and socket.is_connected_to_host())

#func _physics_process(_delta):
	#if not is_socket():
		##print("no")
		#return
	##print(session.user_id)
	#if not mm_match and not is_matchmaking:
		#is_matchmaking = true
		#_matchmake()
	#
	#if mm_match:
		#if frame_count >= frames_per_update:
			#frame_count = 0
			#_send_vehicle_state()
		#else:
			#frame_count += 1

#func _send_vehicle_state():
	#if not is_socket():
		#return
	#
	#if not level:
		#return
	#
	#if not level.player_vehicle:
		#return
	#
	#var state: Dictionary = level.player_vehicle.get_state()
	#await socket.send_match_state_async(cur_match.match_id, raceOp.CLIENT_UPDATE_VEHICLE_STATE, JSON.stringify(state))

func send_match_state(op_code: int, state: Dictionary):
	if Global.extraPing:
		await get_tree().create_timer(Global.get_extra_ping() / 1000.0).timeout
	
	if not is_socket():
		return false
	
	if not cur_match:
		return false

	var res = await socket.send_match_state_async(cur_match.match_id, op_code, JSON.stringify(state))
	if res.is_exception():
		print("Error sending match state: ", res)
		return false
	
	return true



func _matchmake():
	if not await matchmake():
		print("Failed to matchmake")
		# is_matchmaking = false

func update_username(new_username: String):
	var res: NakamaAPI.ApiRpc = await socket.rpc_async("updateDisplayName", new_username)
	if res.is_exception():
		print("Error setting username")
		return false
	#await reset()
	#await connect_client()
	return true

func matchmake(username: String = ""):
	print("Matchmaking...")
	if not is_socket():
		print("No socket")
		return false
	
	if mm_tickets.size() > 0:
		print("Already have a matchmaking ticket")
		return false
	
	if ready_match:
		print("Already have a ready match")
		return false

	if username:
		var resa = await update_username(username)
		if not resa:
			return false
	
	# Try via list
	var res = await matchmake_list()
	if res:
		return true


	# Try via matchmaker
	res = await matchmake_matchmaker()
	return true
	

func matchmake_list():
	print("Matchmaking via list...")

	var min_players = 1
	var max_players = 11
	var limit = 10
	var authoritative = true
	var label = ""
	var query = "+label.joinable:1 +label.matchType:lobby +label.version:" + Util.version
	var match_type = "lobby"

	var res: NakamaAPI.ApiMatchList = await client.list_matches_async(session, min_players, max_players, limit, authoritative, label, query)
	if res.is_exception():
		print("Error adding match: ", res)
		return false
	
	print("Match list received: ", res.matches.size())
	
	if res.matches.size() == 0:
		query = "+label.joinable:1 +label.matchType:race +label.version:" + Util.version
		match_type = "race"
		res = await client.list_matches_async(session, min_players, max_players, limit, authoritative, label, query)
		if res.is_exception():
			print("Error adding match: ", res)
			return false
		
		if res.matches.size() == 0:
			print("No matches found")
			return false
	
	ready_match = res.matches[0].match_id
	ready_match_type = match_type
	ready_match_label = JSON.parse_string(res.matches[0].label)

	# await join_match(res.matches[0].match_id)


func matchmake_matchmaker():
	print("Matchmaking via matchmaker...")
	var ticket = await get_matchmake_ticket()
	if not ticket:
		print("Failed to get matchmake ticket")
		return false
	
	mm_tickets.append(ticket.ticket)

	return true


func get_matchmake_ticket(max_players: int = 12):
	var string_props: Dictionary = {
		"matchType": "lobby",
		"version": Util.version
	}
	
	var ticket: NakamaRTAPI.MatchmakerTicket = await socket.add_matchmaker_async("*", 2, max_players, string_props, {}, 0)

	if ticket.is_exception():
		print("Error adding matchmaker: ", ticket)
		return null
	
	print("Matchmaker ticket received: ", ticket)
	return ticket


func remove_matchmake_ticket(ticket: String):
	if not is_socket():
		return
	
	var removed: NakamaAsyncResult = await socket.remove_matchmaker_async(ticket)
	if removed.is_exception():
		print("Error removing matchmaker: ", removed)
		return false
	
	print("Matchmaker removed: ", ticket)
	return true

func clear_mm_tickets():
	for ticket in mm_tickets:
		await remove_matchmake_ticket(ticket)
	
	mm_tickets.clear()

func _on_matchmaker_matched(p_matched: NakamaRTAPI.MatchmakerMatched):
	print("Matchmaker matched: ", p_matched)

	if not is_socket():
		return

	for ticket in mm_tickets:
		if ticket != p_matched.ticket:
			await remove_matchmake_ticket(ticket)
	
	mm_tickets.clear()

	ready_match = p_matched.match_id
	ready_match_type = "lobby"
	ready_match_label = {}

	# await join_match(p_matched.match_id)


func join_match(match_id: String):
	if not is_socket():
		return false
	
	await leave_match()
	
	var _match: NakamaRTAPI.Match = await socket.join_match_async(match_id)

	if ready_match == match_id:
		ready_match = ""
		ready_match_type = ""
		ready_match_label = {}

	if _match.is_exception():
		print("Error joining match: ", _match)
		return false
	
	print("Match joined: ", _match)

	cur_match = _match
	return true
	# is_matchmaking = false

func leave_match():
	if not cur_match:
		return true
	
	var res: NakamaAsyncResult = await socket.leave_match_async(cur_match.match_id)
	if res.is_exception():
		reset()
		return true
	return true

func connect_client():
	client = Nakama.create_client("GodotArcadeRacerTest", "185.252.235.108", 7350, "http", 10, NakamaLogger.LOG_LEVEL.INFO) as NakamaClient
	client.timeout = 10
	socket = Nakama.create_socket_from(client) as NakamaSocket

	var device_id = OS.get_unique_id() + session_seed

	var _session = await client.authenticate_device_async(device_id)
	if _session.is_exception():
		print("Error creating session: ", _session)
		return false
	session = _session
	print("Session authenticated: ", session)

	var connected: NakamaAsyncResult = await socket.connect_async(session)
	if connected.is_exception():
		print("Error connecting socket: ", connected)
		return false

	print("Socket connected")

	#socket.received_match_presence.connect(_on_match_presence)
	#socket.received_match_state.connect(_on_match_state)
	socket.received_matchmaker_matched.connect(_on_matchmaker_matched)

	return true


func get_display_name():
	if not session:
		return ""
	
	var res: NakamaAPI.ApiRpc = await Network.socket.rpc_async("getDisplayName")
	if res.is_exception():
		print("Error getting display name")
		return ""
	
	return res.payload

#func _on_match_presence(p_presence : NakamaRTAPI.MatchPresenceEvent):
	#print("Match presence: ", p_presence)
	#if level:
		#for p in p_presence.joins:
			#print("Player joined: ", p.user_id)
			#level.removed_player_ids.erase(p.user_id)
			## level.on_player_join(p)
		#for p in p_presence.leaves:
			#print("Player left: ", p.user_id)
			#if p.user_id in level.players_dict:
				#var player: Vehicle3 = level.players_dict[p.user_id]
				#level.players_dict.erase(p.user_id)
				#level.removed_player_ids.append(p.user_id)
				#player.queue_free()
			## level.on_player_leave(p)


#func _on_match_state(match_state : NakamaRTAPI.MatchData):
	#match match_state.op_code:
		#raceOp.SERVER_UPDATE_VEHICLE_STATE:
			#_update_vehicle_state(match_state)
		#_:
			#print("Unknown match state op code: ", match_state.op_code)

#func _update_vehicle_state(match_state : NakamaRTAPI.MatchData):
	#if not level:
		#return
	#
	#level.update_vehicle_state(JSON.parse_string(match_state.data), match_state.presence.user_id)

func on_exit_async():
	await reset()
