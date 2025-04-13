extends Node

class_name PhysicalItem

var key: String
var world: RaceBase
var origin_id: String:
	set(value):
		origin_id = value
		origin = world.players_dict[value]
var owner_id: String:
	set(value):
		owner_id = value
		owned_by = world.players_dict[value]

var origin: Vehicle4
var owned_by: Vehicle4

@export var no_updates := false

func setup(new_key: String, new_world: RaceBase, new_origin: Vehicle4) -> void:
	key = new_key
	world = new_world
	origin_id = new_origin.user_id
	owner_id = new_origin.user_id

func destroy() -> void:
	world.destroy_physical_item(key)

func on_destroy() -> void:
	return

func get_state() -> Dictionary:
	return {}

func set_state(state: Dictionary) -> void:
	return
