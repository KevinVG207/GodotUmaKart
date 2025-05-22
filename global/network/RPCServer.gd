extends Node

@rpc("any_peer", "reliable")
func initialize_player(data: PackedByteArray) -> void:
	return

@rpc("any_peer", "reliable")
func get_rooms() -> void:
	return

@rpc("any_peer", "reliable")
func join_random_room() -> void:
	return
