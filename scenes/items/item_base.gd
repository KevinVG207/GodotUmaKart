extends Node

class_name ItemBase

@export var texture: CompressedTexture2D

func use(player: Vehicle3, world: RaceBase) -> ItemBase:
	self.queue_free()
	return null
