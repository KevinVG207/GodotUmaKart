extends Node

class_name PhysicalItem

var key: String
var world: RaceBase
var origin_id: int:
	set(value):
		origin_id = value
		origin = world.players_dict[value]
var owner_id: int:
	set(value):
		owner_id = value
		owned_by = world.players_dict[value]

var origin: Vehicle4
var owned_by: Vehicle4
var is_transferring_ownership := false

var state_idx: int = 0

@export var destroys_objects := true
@export var no_updates := false

@export_group("Active Effects")
@export var is_active_item: bool = false
@export var control_vehicle: bool = false
@export var speed_multi: float = 1.0
@export var accel_multi: float = 1.0
@export var turn_multi: float = 1.0
@export var gravity_multi: float = 1.0
@export var air_turn_multi: float = 2.0
@export var do_damage_type: Vehicle4.DamageType = Vehicle4.DamageType.NONE
@export var ignore_boost: bool = false
@export var ignore_offroad: bool = false

func setup(new_key: String, new_world: RaceBase, new_origin: Vehicle4) -> void:
	key = new_key
	world = new_world
	origin_id = new_origin.user_id
	owner_id = new_origin.user_id
	if is_active_item:
		owned_by.active_items.append(self)

func _physics_process(_delta: float) -> void:
	if key in world.deleted_physical_items:
		self.queue_free()
		return

func destroy() -> void:
	owned_by.active_items.erase(self)
	world.destroy_physical_item(key)

func on_destroy() -> void:
	return

func get_state() -> Dictionary:
	return {}

func set_state(state: Dictionary) -> void:
	return

func _on_owner_changed(old_owner: Vehicle4, new_owner: Vehicle4) -> void:
	if is_active_item:
		old_owner.active_items.erase(self)
		new_owner.active_items.append(self)
	return
