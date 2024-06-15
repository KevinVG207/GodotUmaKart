extends Node

var randPing = 0
var unique_string = OS.get_unique_id()

const MODE1_OFFLINE = 0
const MODE1_ONLINE = 1

const MODE2_RACE = 0
const MODE2_TIMETRIALS = 1
const MODE2_BATTLE = 2
const MODE2_MISSION = 3

var MODE1: int = MODE1_OFFLINE
var MODE2: int = MODE2_RACE

var trick_col_to_node = {
	"trick": "NormalBoostTimer",
	"small_trick": "SmallBoostTimer"
}

var items: Array = [
	load("res://scenes/items/1carrot.tscn"),
	#preload("res://scenes/items/2carrots.tscn"),
	load("res://scenes/items/3carrots.tscn"),
	load("res://scenes/items/GreenShell.tscn")
]

var physical_items: Dictionary = {
	"green_shell": load("res://scenes/items/_physical/DraggedGreenShell.tscn"),
	"thrown_green_shell": load("res://scenes/items/_physical/ThrownGreenShell.tscn")
}

var item_tex: Array = []

func _enter_tree():
	#TranslationServer.set_locale("ja")
	return

func _ready():
	for item: PackedScene in items:
		var instance = item.instantiate()
		item_tex.append(instance.texture)
		instance.queue_free()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await Network.on_exit_async()
		get_tree().quit()
