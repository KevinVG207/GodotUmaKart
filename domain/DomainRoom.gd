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
	
	static func deserialize(list: Array[Variant]) -> Room:
		var o := Room.new()
		generic_deserialize_room(o, list)
		return o
	
	static func generic_deserialize_room(room: DomainRoom.Room, list: Array[Variant]) -> void:
		room.id = list.pop_front()
		room.type = list.pop_front()
		room.max_players = list.pop_front()
		room.joinable = list.pop_front()
		var players_dict: Dictionary[int, Array] = list.pop_front()
		for pid in players_dict:
			room.players[pid] = DomainPlayer.Player.deserialize(players_dict[pid])
		room.tick = list.pop_front()
		room.tick_rate = list.pop_front()

class Lobby extends Room:
	var votes: Dictionary[int, VoteData]
	var voting_timeout: int = 30 * tick_rate
	var joining_timeout: int = 15 * tick_rate
	var winning_vote: int = 0
	
	func _init() -> void:
		self.type = RoomType.LOBBY
	
	static func deserialize(list: Array[Variant]) -> Lobby:
		var lobby := Lobby.new()
		generic_deserialize_room(lobby, list)
		var tmp_votes := list.pop_front() as Dictionary[int, Array]
		for vote_id in tmp_votes:
			lobby.votes[vote_id] = VoteData.deserialize(tmp_votes[vote_id])
		lobby.voting_timeout = list.pop_front()
		lobby.joining_timeout = list.pop_front()
		lobby.winning_vote = list.pop_front()
		return lobby

class Race extends Room:
	var course_name: String = ""
	var starting_order: Array[int] = []
	
	func _init() -> void:
		self.type = RoomType.RACE

	static func deserialize(list: Array[Variant]) -> Race:
		var race := Race.new()
		generic_deserialize_room(race, list)
		race.course_name = list.pop_front()
		race.starting_order = list.pop_front()
		return race

enum FinishType {
	NORMAL,
	TIMEOUT
}

class FinishData:
	var finish_order: Array[int]
	var type: FinishType
	
	func serialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(finish_order)
		list.append(type)
		return list
	
	static func deserialize(list: Array[Variant]) -> FinishData:
		var o := FinishData.new()
		o.finish_order = list.pop_front()
		o.type = list.pop_front()
		return o


class VoteData:
	var course_name: String = ""
	var character_id: int = 0
	var vehicle_id: int = 0

	func serialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(course_name)
		list.append(character_id)
		list.append(vehicle_id)
		return list

	static func deserialize(list: Array[Variant]) -> VoteData:
		var o := VoteData.new()
		o.course_name = list.pop_front()
		o.character_id = list.pop_front()
		o.vehicle_id = list.pop_front()
		return o
