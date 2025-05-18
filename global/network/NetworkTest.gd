extends Node

const SERVER_IP := "localhost"
const SERVER_PORT := 31500
var peer_id: int
var our_player: DomainPlayer.Player

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	RPCClient.get_rooms_result.connect(_on_get_rooms)
	RPCClient.initialize_player_result.connect(_on_initialize_player_result)
	
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	multiplayer.multiplayer_peer = peer

func _on_connected_to_server() -> void:
	peer_id = multiplayer.get_unique_id()
	print("Client: connected to server as ", peer_id)
	var data := DomainPlayer.PlayerInitializeData.new()
	data.username = "DEFAULT_USERNAME_" + str(randi())
	RPCServer.initialize_player.rpc_id(1, data.deserialize())

func _on_connection_failed() -> void:
	print("Client: connection failed")

func _on_server_disconnected() -> void:
	print("Client: server disconnected")

func _on_get_rooms(rooms: Array[DomainRoom.Room]) -> void:
	print("Client: Get rooms")
	for room in rooms:
		print("Room data")
		print("ID: ", room.id)
		print("Type: ", room.type)
		print("Players:")
		for player in room.players:
			print("\t", player.peer_id, ": ", player.username)

func _on_initialize_player_result(player: DomainPlayer.Player) -> void:
	print("Initialized player")
	our_player = player
	RPCServer.get_rooms.rpc_id(1)
