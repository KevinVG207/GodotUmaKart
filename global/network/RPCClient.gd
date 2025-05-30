extends Node

signal error_received(code: int)
@rpc("reliable")
func error(code: int) -> void:
	print("DISCONNECT WITH ERROR CODE ", code)
	Network.reset()
	error_received.emit(code)

signal initialize_player_result(player: DomainPlayer.Player)
@rpc("reliable")
func initialize_player(list: Array[Variant]) -> void:
	var player := DomainPlayer.Player.deserialize(list)
	initialize_player_result.emit(player)

signal get_rooms_result(rooms: Array[DomainRoom.Room])
@rpc("reliable")
func get_rooms(input: Array[Array]) -> void:
	var out: Array[DomainRoom.Room] = []
	for room_data in input:
		out.append(DomainRoom.Room.deserialize(room_data))
	get_rooms_result.emit(out)

signal join_room_result(room: DomainRoom.Room)
@rpc("reliable")
func join_lobby_room(list: Array[Variant]) -> void:
	join_room_result.emit(DomainRoom.Lobby.deserialize(list) as DomainRoom.Room)

@rpc("reliable")
func join_race_room(list: Array[Variant]) -> void:
	join_room_result.emit(DomainRoom.Race.deserialize(list) as DomainRoom.Room)

signal player_joined_room_received(player: DomainPlayer.Player)
@rpc("reliable")
func player_joined_room(list: Array[Variant]) -> void:
	print("RPCClient player_joined_room")
	var player := DomainPlayer.Player.deserialize(list)
	player_joined_room_received.emit(player)

signal player_left_room_received(player: DomainPlayer.Player, is_transfer: bool)
@rpc("reliable")
func player_left_room(list: Array[Variant], is_transfer: bool) -> void:
	var player := DomainPlayer.Player.deserialize(list)
	player_left_room_received.emit(player, is_transfer)

signal update_lobby_received(lobby: DomainRoom.Lobby)
@rpc("reliable")
func update_lobby(list: Array[Variant]) -> void:
	update_lobby_received.emit(DomainRoom.Lobby.deserialize(list))

@rpc("reliable")
func receive_final_lobby(list: Array[Variant]) -> void:
	print("FINAL LOBBY RECEIVED")
	Global.final_lobby = DomainRoom.Lobby.deserialize(list)

signal ping_received(ping: int)
@rpc("reliable")
func receive_ping(tick: int, ping: int) -> void:
	ping_received.emit(ping)
	if Global.extraPing:
		await get_tree().create_timer(Global.get_extra_ping() / 1000.0 * 2).timeout
	RPCServer.send_ping.rpc_id(1, tick)

signal race_start_received(ticks_to_start: int, tick_rate: int, ping: int)
@rpc("reliable")
func race_start(ticks_to_start: int, tick_rate: int, ping: int) -> void:
	print("RACE START DATA RECEIVED")
	race_start_received.emit(ticks_to_start, tick_rate, ping)

signal race_vehicle_state_received(vehicle: DomainRace.VehicleDataWrapper)
@rpc("unreliable_ordered")
func race_vehicle_state(list: Array[Variant]) -> void:
	race_vehicle_state_received.emit(DomainRace.VehicleDataWrapper.deserialize(list))

signal race_spawn_item_received(dto: DomainRace.ItemSpawnWrapper)
@rpc("reliable")
func race_spawn_item(list: Array[Variant]) -> void:
	race_spawn_item_received.emit(DomainRace.ItemSpawnWrapper.deserialize(list))

signal race_destroy_item_received(key: String)
@rpc("reliable")
func race_destroy_item(key: String) -> void:
	race_destroy_item_received.emit(key)

signal race_item_state_received(dto: DomainRace.ItemStateWrapper)
@rpc("unreliable")
func race_item_state(list: Array[Variant]) -> void:
	race_item_state_received.emit(DomainRace.ItemStateWrapper.deserialize(list))

signal race_finished_received(dto: DomainRoom.FinishData)
@rpc("reliable")
func race_finished(list: Array[Variant]) -> void:
	race_finished_received.emit(DomainRoom.FinishData.deserialize(list))

signal race_item_transfer_owner_received(key: String, new_owner_id: int)
@rpc("reliable")
func race_item_transfer_owner(key: String, new_owner_id: int) -> void:
	race_item_transfer_owner_received.emit(key, new_owner_id)
