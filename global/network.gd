extends Node

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket

var level: LevelBase

var is_matchmaking: bool = false
var is_in_match: bool = false

var mm_tickets: Array = []
var mm_matched_data: NakamaRTAPI.MatchmakerMatched = null
var mm_match: NakamaRTAPI.Match = null

var frames_per_update: int = 6
var frame_count: int = 0

class raceOp:
	const SERVER_UPDATE_VEHICLE_STATE = 1
	const CLIENT_UPDATE_VEHICLE_STATE = 2

func _ready():
	await connect_client()

func is_socket():
	return (socket and socket.is_connected_to_host())

func _physics_process(_delta):
	if not is_socket():
		#print("no")
		return
	#print(session.user_id)
	if not mm_match and not is_matchmaking:
		is_matchmaking = true
		_matchmake()
	
	if mm_match:
		if frame_count >= frames_per_update:
			frame_count = 0
			_send_vehicle_state()
		else:
			frame_count += 1

func _send_vehicle_state():
	if not is_socket():
		return
	
	if not level:
		return
	
	if not level.player_vehicle:
		return
	
	var state: Dictionary = level.player_vehicle.get_state()
	await socket.send_match_state_async(mm_match.match_id, raceOp.CLIENT_UPDATE_VEHICLE_STATE, JSON.stringify(state))

func _matchmake():
	if not await matchmake():
		print("Failed to matchmake")
		is_matchmaking = false


func matchmake():
	print("Matchmaking...")
	if not is_socket():
		print("No socket")
		return false
	
	if mm_tickets.size() > 0:
		print("Already have a matchmaking ticket")
		return false
	
	var ticket = await get_matchmake_ticket()
	if not ticket:
		print("Failed to get matchmake ticket")
		return false
	
	mm_tickets.append(ticket.ticket)
	return true



func get_matchmake_ticket():
	var string_props: Dictionary = {
		"matchType": "race"
	}
	var ticket: NakamaRTAPI.MatchmakerTicket = await socket.add_matchmaker_async("*", 2, 4, string_props, {}, 0)

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


func _on_matchmaker_matched(p_matched: NakamaRTAPI.MatchmakerMatched):
	print("Matchmaker matched: ", p_matched)

	if not is_socket():
		return

	for ticket in mm_tickets:
		if ticket != p_matched.ticket:
			await remove_matchmake_ticket(ticket)
	
	mm_tickets.clear()

	mm_matched_data = p_matched

	var _match: NakamaRTAPI.Match = await socket.join_match_async(p_matched.match_id)

	if _match.is_exception():
		print("Error joining match: ", _match)
		return
	
	print("Match joined: ", _match)

	mm_match = _match
	is_matchmaking = false


func connect_client():
	client = Nakama.create_client("GodotArcadeRacerTest", "185.252.235.108", 7350, "http") as NakamaClient
	client.timeout = 10
	socket = Nakama.create_socket_from(client) as NakamaSocket

	var device_id = OS.get_unique_id() + str(randi_range(1, 99999999))

	session = await client.authenticate_device_async(device_id)
	if session.is_exception():
		print("Error creating session: ", session)
		return false
	print("Session authenticated: ", session)

	var connected: NakamaAsyncResult = await socket.connect_async(session)
	if connected.is_exception():
		print("Error connecting socket: ", connected)
		return false

	print("Socket connected")

	socket.received_match_presence.connect(_on_match_presence)
	socket.received_match_state.connect(_on_match_state)
	socket.received_matchmaker_matched.connect(_on_matchmaker_matched)

	level.player_user_id = session.user_id

	return true


func _on_match_presence(p_presence : NakamaRTAPI.MatchPresenceEvent):
	print("Match presence: ", p_presence)
	if level:
		for p in p_presence.joins:
			print("Player joined: ", p.user_id)
			# level.on_player_join(p)
		for p in p_presence.leaves:
			print("Player left: ", p.user_id)
			if p.user_id in level.players_dict:
				level.players_dict.erase(p.user_id)
			# level.on_player_leave(p)


func _on_match_state(match_state : NakamaRTAPI.MatchData):
	match match_state.op_code:
		raceOp.SERVER_UPDATE_VEHICLE_STATE:
			_update_vehicle_state(match_state)
		_:
			print("Unknown match state op code: ", match_state.op_code)

func _update_vehicle_state(match_state : NakamaRTAPI.MatchData):
	if not level:
		return
	
	level.update_vehicle_state(JSON.parse_string(match_state.data), match_state.presence.user_id)


func on_exit_async():
	await client.session_logout_async(session)
