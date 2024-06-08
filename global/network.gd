extends Node

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket

var level: LevelBase

class OP:
	const VEHICLE_STATE = 1

func _ready():
	await connect_client()

func connect_client():
	client = Nakama.create_client("GodotArcadeRacerTest", "185.252.235.108", 7350, "http") as NakamaClient
	client.timeout = 10
	socket = Nakama.create_socket_from(client) as NakamaSocket

	var device_id = OS.get_unique_id()

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

	return true


func _on_match_presence(p_presence : NakamaRTAPI.MatchPresenceEvent):
	if level:
		for p in p_presence.joins:
			level.on_player_join(p)
		for p in p_presence.leaves:
			level.on_player_leave(p)


func _on_match_state(match_state : NakamaRTAPI.MatchData):
	pass


func on_exit_async():
	await client.session_logout_async(session)
