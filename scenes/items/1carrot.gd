extends ItemBase

func use(player: Vehicle3, world: RaceBase) -> ItemBase:
	player.normal_boost_timer.start(player.normal_boost_duration)
	self.queue_free()
	return null
