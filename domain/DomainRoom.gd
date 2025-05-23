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
	var players: Dictionary[int, DomainPlayer.Player] = {}
	var tick: int = 0
	var tick_rate: int = 10
	
	static func serialize(list: Array[Variant]) -> Room:
		var o := Room.new()
		generic_serialize_room(o, list)
		return o
	
	static func generic_serialize_room(room: DomainRoom.Room, list: Array[Variant]) -> void:
		room.id = list.pop_front()
		room.type = list.pop_front()
		room.max_players = list.pop_front()
		room.joinable = list.pop_front()
		var players_dict: Dictionary[int, Array] = list.pop_front()
		for id in players_dict:
			room.players[id] = DomainPlayer.Player.serialize(players_dict[id])
		room.tick = list.pop_front()
		room.tick_rate = list.pop_front()

class Lobby extends Room:
	var votes: Dictionary[int, VoteData]
	
	func _init() -> void:
		self.type = RoomType.LOBBY
	
	static func serialize(list: Array[Variant]) -> Lobby:
		var lobby := Lobby.new()
		generic_serialize_room(lobby, list)
		var tmp_votes = list.pop_front() as Dictionary[int, Array]
		for vote_id in tmp_votes:
			lobby.votes[vote_id] = VoteData.serialize(tmp_votes[vote_id])
		return lobby

class Race extends Room:
	var course_name: String = ""
	
	func _init() -> void:
		self.type = RoomType.RACE

	static func serialize(list: Array[Variant]) -> Race:
		var race := Race.new()
		generic_serialize_room(race, list)
		race.course_name = list.pop_front()
		return race

class VoteData:
	var course_name: String = ""
	var character_id: int = 0
	var vehicle_id: int = 0

	func deserialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(course_name)
		list.append(character_id)
		list.append(vehicle_id)
		return list

	static func serialize(list: Array[Variant]) -> VoteData:
		var o := VoteData.new()
		o.course_name = list.pop_front()
		o.character_id = list.pop_front()
		o.vehicle_id = list.pop_front()
		return o
