extends Node

class_name UsableItem

@export var wheel_image: CompressedTexture2D
@export var probability: Curve
@export var physical_item_key: String

var owned_by: Vehicle4
var world: RaceBase

func use() -> void:
	if physical_item_key:
		world.make_physical_item(physical_item_key, owned_by)
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
	UI.race_ui.update_item_image(img)
