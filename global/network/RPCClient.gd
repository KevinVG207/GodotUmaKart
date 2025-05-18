extends Node

signal error_received(code: int)
@rpc("reliable")
func error(code: int) -> void:
	print("DISCONNECT WITH ERROR CODE ", code)
	multiplayer.multiplayer_peer = null
	error_received.emit(code)

signal initialize_player_result(player: DomainPlayer.Player)
@rpc("reliable")
func initialize_player(data: PackedByteArray) -> void:
	var player := DomainPlayer.Player.serialize(data)
	initialize_player_result.emit(player)

signal get_rooms_result(rooms: Array[DomainRoom.Room])
@rpc("reliable")
func get_rooms(data: PackedByteArray) -> void:
	var input: Array[PackedByteArray] = bytes_to_var(data)
	var out: Array[DomainRoom.Room] = []
	for room_data in input:
		out.append(DomainRoom.Room.serialize(room_data))
	get_rooms_result.emit(out)
