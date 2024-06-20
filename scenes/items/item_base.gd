extends Node

class_name ItemBase

@export var texture: CompressedTexture2D
@export var from_pos: int = 1
@export var to_pos: int = 12

func use(player: Vehicle3, world: RaceBase) -> ItemBase:
	self.queue_free()
	return null
