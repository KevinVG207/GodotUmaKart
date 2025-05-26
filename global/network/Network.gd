extends Node

#const SERVER_IP := "localhost"
const SERVER_IP := "game.umapyoi.net"
const SERVER_PORT := 31500
var peer_id: int
var our_username: String = ""
var our_player: DomainPlayer.Player
var our_room: DomainRoom.Room

signal connection_success
signal connection_failed
signal initialization_success

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	RPCClient.initialize_player_result.connect(_on_initialize_player_result)
	RPCClient.join_room_result.connect(_on_joined_room)
	RPCClient.update_lobby_received.connect(_on_update_lobby)
	RPCClient.player_joined_room_received.connect(_on_other_player_joined)
	RPCClient.player_left_room_received.connect(_on_other_player_left)

func setup() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	multiplayer.multiplayer_peer = peer

func reset() -> void:
	multiplayer.multiplayer_peer = null
	our_player = null
	our_room = null

func _on_connected_to_server() -> void:
	peer_id = multiplayer.get_unique_id()
	print("Client: connected to server as ", peer_id)
	connection_success.emit()

func _on_connection_failed() -> void:
	print("Client: connection failed")
	connection_failed.emit()

func _on_server_disconnected() -> void:
	print("Client: server disconnected")
	RPCClient.error(DomainError.SERVER_DISCONNECT)

func _on_get_rooms(rooms: Array[DomainRoom.Room]) -> void:
	print("Client: Get rooms")
	for room in rooms:
		print("Room data")
		print("ID: ", room.id)
		print("Type: ", room.type)
		print("Players:")
		for player in room.players.values():
			print("\t", player.peer_id, ": ", player.username)

func initialize_player() -> void:
	var data := DomainPlayer.PlayerInitializeData.new()
	data.username = our_username
	RPCServer.initialize_player.rpc_id(1, data.serialize())

func _on_initialize_player_result(player: DomainPlayer.Player) -> void:
	print("Initialized player")
	our_player = player
	initialization_success.emit()

func join_random_room() -> void:
	RPCServer.join_random_room.rpc_id(1)

func _on_joined_room(room: DomainRoom.Room) -> void:
	our_room = room
	print("Server assigned us to ", DomainRoom.RoomType.find_key(room.type), " room: ", room.id)

func _on_other_player_joined(player: DomainPlayer.Player) -> void:
	print("Player joined our room: ", player.peer_id)
	our_room.players[player.peer_id] = player

func _on_other_player_left(player: DomainPlayer.Player, _is_transfer: bool) -> void:
	print("Player left our room: ", player.peer_id)
	our_room.players.erase(player.peer_id)

func _on_update_lobby(lobby: DomainRoom.Lobby) -> void:
	our_room = lobby as DomainRoom.Room
