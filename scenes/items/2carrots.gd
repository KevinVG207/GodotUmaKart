extends ItemBase

var next_item := preload("res://scenes/items/1carrot.tscn")

func use(player: Vehicle4, _world: RaceBase) -> ItemBase:
	player.apply_boost(Vehicle4.BoostType.NORMAL)
	self.queue_free()
	return next_item.instantiate()
