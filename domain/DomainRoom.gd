extends Node

class_name DomainRoom

enum RoomType {
	LOBBY,
	RACE
}

class Room:
	var id: String
	var type: RoomType
	var max_players: int = 12
	var joinable: bool = false
	var players: Array[DomainPlayer.Player] = []
	
	func _init() -> void:
		self.id = UUID.v4()
	
	func deserialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(id)
		list.append(type)
		list.append(max_players)
		list.append(joinable)
		var players_list: Array[Array] = []
		for player in players:
			players_list.append(player.deserialize())
		list.append(players_list)
		return list
	
	static func serialize(list: Array[Variant]) -> Room:
		var o := Room.new()
		o.id = list.pop_front()
		o.type = list.pop_front()
		o.max_players = list.pop_front()
		o.joinable = list.pop_front()
		var players_list: Array[Array] = list.pop_front()
		for player_data in players_list:
			o.players.append(DomainPlayer.Player.serialize(player_data))
		return o
	
	func _on_player_join_room(player: DomainPlayer.Player) -> void:
		_update_joinable()
		return
	
	func _on_player_leave_room(player: DomainPlayer.Player) -> void:
		_update_joinable()
		return
	
	func _update_joinable() -> void:
		if players.size() >= max_players:
			joinable = false;
		else:
			joinable = true;

class Lobby extends Room:
	func _init() -> void:
		super()
		self.type = RoomType.LOBBY

class Race extends Room:
	func _init() -> void:
		super()
		self.type = RoomType.RACE
