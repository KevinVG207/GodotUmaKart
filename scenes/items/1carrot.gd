extends ItemBase

func use(player: Vehicle4, _world: RaceBase) -> ItemBase:
	player.apply_boost(Vehicle4.BoostType.NORMAL)
	self.queue_free()
	return null
