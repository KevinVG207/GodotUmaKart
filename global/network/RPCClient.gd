extends Node

signal error_received(code: int)
@rpc("reliable")
func error(code: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	print("DISCONNECT WITH ERROR CODE ", code)
	multiplayer.multiplayer_peer = null
	error_received.emit(code)

signal initialize_player_result(player: DomainPlayer.Player)
@rpc("reliable")
func initialize_player(data: PackedByteArray) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	var player := DomainPlayer.Player.serialize(bytes_to_var(data))
	initialize_player_result.emit(player)

signal get_rooms_result(rooms: Array[DomainRoom.Room])
@rpc("reliable")
func get_rooms(data: PackedByteArray) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	var input: Array[Array] = bytes_to_var(data)
	var out: Array[DomainRoom.Room] = []
	for room_data in input:
		out.append(DomainRoom.Room.serialize(room_data))
	get_rooms_result.emit(out)

signal join_random_room_result(room: DomainRoom.Room)
@rpc("reliable")
func join_random_room(data: PackedByteArray) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	join_random_room_result.emit(DomainRoom.Room.serialize(bytes_to_var(data)))

signal player_joined_room_received(player: DomainPlayer.Player)
@rpc("reliable")
func player_joined_room(list: Array[Variant]) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	var player = DomainPlayer.Player.serialize(list)
	player_joined_room_received.emit(player)

signal player_left_room_received(player: DomainPlayer.Player)
@rpc("reliable")
func player_left_room(list: Array[Variant]) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	var player = DomainPlayer.Player.serialize(list)
	player_left_room_received.emit(player)
