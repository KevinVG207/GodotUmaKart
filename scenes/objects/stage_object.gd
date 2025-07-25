extends Node3D

class_name StageObject

@onready var world: RaceBase = Util.find_race_base_parent(self)
@export var triggered_by_player: bool = false
@export var player_trigger_with_boost: bool = false
@export var player_trigger_with_damage: bool = false

var no_bounce: bool = false

func _hit_by_item(item: PhysicalItem) -> void:
	if Global.MODE1 == Global.MODE1_ONLINE and item.owned_by != world.player_vehicle:
		return
	trigger()

func _hit_by_vehicle(player: Vehicle4) -> void:
	if Global.MODE1 == Global.MODE1_ONLINE and player != world.player_vehicle:
		return
	
	if !triggered_by_player:
		return
	
	if !player_trigger_with_boost and !player_trigger_with_damage:
		trigger()
		return
	
	if player_trigger_with_boost and player.cur_boost_type != Vehicle4.BoostType.NONE:
		trigger()
		return
	
	elif player_trigger_with_damage and player.do_damage_type != Vehicle4.DamageType.NONE:
		trigger()
		return
	
	

func trigger() -> void:
	return
