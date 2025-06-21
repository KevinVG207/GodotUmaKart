extends Node

class_name UsableItem

@export var wheel_image: CompressedTexture2D
@export var probability: Curve
@export var physical_item_key: String
@export var track_physical_item: bool = false
var tracked: String = ""

var owned_by: Vehicle4
var world: RaceBase
var used: bool = false

func use() -> void:
	if used:
		return

	used = true
	
	if physical_item_key:
		tracked = world.make_physical_item(physical_item_key, owned_by).key
	
	if !track_physical_item:
		clear()
	
	if owned_by.is_player:
		UI.race_ui.play_roulette_use()

func _physics_process(_delta: float) -> void:
	if track_physical_item and tracked in world.deleted_physical_items:
		track_physical_item = false
		clear()
	

func setup(new_owner: Vehicle4, new_world: RaceBase) -> void:
	owned_by = new_owner
	world = new_world
	update_image(wheel_image)

func clear() -> void:
	owned_by.remove_item()
	queue_free()

func replace_item(item: UsableItem) -> void:
	owned_by.replace_item(item)

func update_image(img: CompressedTexture2D) -> void:
	if !owned_by.is_player:
		return
	UI.race_ui.update_item_image(img)
	if owned_by.is_player:
		UI.race_ui.play_roulette_use()
