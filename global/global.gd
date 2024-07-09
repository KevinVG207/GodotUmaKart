extends Node

signal goto_lobby_screen

var player_count = 12

var randPing = 0
var unique_string = OS.get_unique_id()

var locales = [
	"en",
	"ja"
]

var cur_locale: int = 0:
	set(value):
		TranslationServer.set_locale(locales[value])
		cur_locale = value

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
	load("res://scenes/items/GreenBean.tscn"),
	load("res://scenes/items/RedBean.tscn"),
	load("res://scenes/items/Book.tscn")
]

var item_dist: Array = []

var physical_items: Dictionary = {
	"green_bean": load("res://scenes/items/_physical/DraggedGreenBean.tscn"),
	"thrown_green_bean": load("res://scenes/items/_physical/ThrownGreenBean.tscn"),
	"book": load("res://scenes/items/_physical/DraggedBook.tscn"),
	"thrown_book": load("res://scenes/items/_physical/ThrownBook.tscn"),
	"red_bean": load("res://scenes/items/_physical/DraggedRedBean.tscn"),
	"thrown_red_bean": load("res://scenes/items/_physical/ThrownRedBean.tscn")
}

var item_tex: Array = []

func _enter_tree():
	#seed(1)
	TranslationServer.set_locale(locales[cur_locale])
	return

func _ready():
	#item_dist.resize(12)
	for _i in range(player_count):
		item_dist.append([])
	
	for item: PackedScene in items:
		var instance = item.instantiate()
		item_tex.append(instance.texture)
		for i in range(instance.from_pos-1, instance.to_pos):
			if i < player_count:
				item_dist[i].append(item)
		instance.queue_free()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await Network.on_exit_async()
		get_tree().quit()
