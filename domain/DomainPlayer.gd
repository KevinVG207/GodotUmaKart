extends Node

class_name DomainPlayer

class Player:
	var peer_id: int
	var username: String
	var room_id: String = ""
	
	func deserialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(peer_id)
		list.append(username)
		return list

	static func serialize(list: Array[Variant]) -> Player:
		var o := Player.new()
		o.peer_id = list.pop_front()
		o.username = list.pop_front()
		return o

class PlayerInitializeData:
	var username: String
	
	func deserialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(username)
		return list

	static func serialize(list: Array[Variant]) -> PlayerInitializeData:
		var o := PlayerInitializeData.new()
		o.username = list.pop_front()
		return o
