extends ItemBase

func use(player: Vehicle3, world: RaceBase) -> ItemBase:
	world.make_physical_item("green_bean", player)
	self.queue_free()
	return null
