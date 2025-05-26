extends Node

class_name DomainRace


class VehicleDataWrapper:
	var player: DomainPlayer.Player
	var vehicle_state: Dictionary

	func serialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(player.serialize())
		list.append(vehicle_state)
		return list
	
	static func deserialize(list: Array[Variant]) -> VehicleDataWrapper:
		var wrapper := VehicleDataWrapper.new()
		wrapper.player = DomainPlayer.Player.deserialize(list.pop_front())
		wrapper.vehicle_state = list.pop_front()
		return wrapper

class ItemStateWrapper:
	var key: String
	var owner_id: int
	var origin_id: int
	var state: Dictionary
	var state_idx: int

	func serialize() -> Array[Variant]:
		var list: Array[Variant] = []
		list.append(key)
		list.append(owner_id)
		list.append(origin_id)
		list.append(state)
		list.append(state_idx)
		return list

	static func deserialize(list: Array[Variant]) -> ItemStateWrapper:
		var wrapper := ItemStateWrapper.new()
		generic_deserialize(wrapper, list)
		return wrapper
	
	static func generic_deserialize(wrapper: ItemStateWrapper, list: Array[Variant]) -> void:
		wrapper.key = list.pop_front()
		wrapper.owner_id = list.pop_front()
		wrapper.origin_id = list.pop_front()
		wrapper.state = list.pop_front()
		wrapper.state_idx = list.pop_front()

class ItemSpawnWrapper extends ItemStateWrapper:
	var type: String

	func serialize() -> Array[Variant]:
		var list: Array[Variant] = super.serialize()
		list.append(type)
		return list

	static func deserialize(list: Array[Variant]) -> ItemSpawnWrapper:
		var wrapper := ItemSpawnWrapper.new()
		generic_deserialize(wrapper, list)
		wrapper.type = list.pop_front()
		return wrapper
