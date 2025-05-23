extends Node

signal error_received(code: int)
@rpc("reliable")
func error(code: int) -> void:
	print("DISCONNECT WITH ERROR CODE ", code)
	multiplayer.multiplayer_peer = null
	error_received.emit(code)

signal initialize_player_result(player: DomainPlayer.Player)
@rpc("reliable")
func initialize_player(list: Array[Variant]) -> void:
	var player := DomainPlayer.Player.serialize(list)
	initialize_player_result.emit(player)

signal get_rooms_result(rooms: Array[DomainRoom.Room])
@rpc("reliable")
func get_rooms(input: Array[Array]) -> void:
	var out: Array[DomainRoom.Room] = []
	for room_data in input:
		out.append(DomainRoom.Room.serialize(room_data))
	get_rooms_result.emit(out)

signal join_room_result(room: DomainRoom.Room)
@rpc("reliable")
func join_lobby_room(list: Array[Variant]) -> void:
	join_room_result.emit(DomainRoom.Lobby.serialize(list) as DomainRoom.Room)

@rpc("reliable")
func join_race_room(list: Array[Variant]) -> void:
	join_room_result.emit(DomainRoom.Race.serialize(list) as DomainRoom.Room)

signal player_joined_room_received(player: DomainPlayer.Player)
@rpc("reliable")
func player_joined_room(list: Array[Variant]) -> void:
	print("RPCClient player_joined_room")
	var player = DomainPlayer.Player.serialize(list)
	player_joined_room_received.emit(player)

signal player_left_room_received(player: DomainPlayer.Player)
@rpc("reliable")
func player_left_room(list: Array[Variant]) -> void:
	var player = DomainPlayer.Player.serialize(list)
	player_left_room_received.emit(player)

signal update_lobby_received(lobby: DomainRoom.Lobby)
@rpc("reliable")
func update_lobby(list: Array[Variant]) -> void:
	update_lobby_received.emit(DomainRoom.Lobby.serialize(list))
