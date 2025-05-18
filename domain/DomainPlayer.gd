extends Node

class_name DomainPlayer

class Player:
	var peer_id: int
	var username: String
	var room_id: String = ""
	
	func deserialize() -> PackedByteArray:
		var list: Array[Variant] = []
		list.append(peer_id)
		list.append(username)
		return var_to_bytes(list)

	static func serialize(data: PackedByteArray) -> Player:
		var list: Array[Variant] = bytes_to_var(data)
		var o := Player.new()
		o.peer_id = list.pop_front()
		o.username = list.pop_front()
		return o

class PlayerInitializeData:
	var username: String
	
	func deserialize() -> PackedByteArray:
		var list: Array[Variant] = []
		list.append(username)
		return var_to_bytes(list)

	static func serialize(data: PackedByteArray) -> PlayerInitializeData:
		var list: Array[Variant] = bytes_to_var(data)
		var o := PlayerInitializeData.new()
		o.username = list.pop_front()
		return o
