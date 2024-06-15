extends ItemBase

var next_item = preload("res://scenes/items/1carrot.tscn")

func use(player: Vehicle3, world: RaceBase) -> ItemBase:
	player.normal_boost_timer.start(player.normal_boost_duration)
	self.queue_free()
	return next_item.instantiate()
