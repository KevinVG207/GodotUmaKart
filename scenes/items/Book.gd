extends ItemBase

func use(player: Vehicle3, world: RaceBase) -> ItemBase:
	world.make_physical_item("book", player)
	self.queue_free()
	return null
