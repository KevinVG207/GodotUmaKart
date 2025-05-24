extends Node

class_name DomainPlayer

class Player:
	var peer_id: int
	var username: String
	var room_id: String = ""
	var ping: int = 250
	
	func serialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(peer_id)
		list.append(username)
		list.append(ping)
		return list

	static func deserialize(list: Array[Variant]) -> Player:
		var o := Player.new()
		o.peer_id = list.pop_front()
		o.username = list.pop_front()
		o.ping = list.pop_front()
		return o

class PlayerInitializeData:
	var username: String
	
	func serialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(username)
		return list

	static func deserialize(list: Array[Variant]) -> PlayerInitializeData:
		var o := PlayerInitializeData.new()
		o.username = list.pop_front()
		return o
