extends Node

var trick_col_to_node = {
	"trick": "NormalBoostTimer",
	"small_trick": "SmallBoostTimer"
}

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await Network.on_exit_async()
		get_tree().quit()
