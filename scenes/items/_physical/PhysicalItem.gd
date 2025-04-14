extends Node3D

class_name PhysicalItemOld

var item_id: String
var owner_id: String
var world: RaceBase
var no_updates: bool = false

func get_state() -> Dictionary:
	return {}
	
func set_state(state: Dictionary) -> void:
	return
