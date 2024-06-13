extends Node

var randPing = 0

const MODE1_OFFLINE = 0
const MODE1_ONLINE = 1

const MODE2_RACE = 0
const MODE2_BATTLE = 1
const MODE2_MISSION = 2

var MODE1: int = MODE1_OFFLINE
var MODE2: int = MODE2_RACE

var trick_col_to_node = {
	"trick": "NormalBoostTimer",
	"small_trick": "SmallBoostTimer"
}

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await Network.on_exit_async()
		get_tree().quit()
