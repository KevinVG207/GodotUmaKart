extends ItemBase

func use(player: Vehicle4, world: RaceBase) -> ItemBase:
	world.make_physical_item("green_bean", player)
	self.queue_free()
	return null
