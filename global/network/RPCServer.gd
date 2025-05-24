extends Node

@rpc("any_peer", "reliable")
func initialize_player(list: Array[Variant]) -> void:
	return

@rpc("any_peer", "reliable")
func get_rooms() -> void:
	return

@rpc("any_peer", "reliable")
func join_random_room() -> void:
	return

@rpc("any_peer", "reliable")
func send_vote(list: Array[Variant]) -> void:
	return

@rpc("any_peer", "reliable")
func send_ping(tick: int) -> void:
	return

@rpc("any_peer", "reliable")
func race_send_ready() -> void:
	return

@rpc("any_peer", "unreliable_ordered")
func race_vehicle_state(state: Dictionary) -> void:
	return
