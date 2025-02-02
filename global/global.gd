extends Node

signal goto_lobby_screen
signal goto_settings_screen

signal camera_switched

var default_player_count: int = 1
var player_count: int = default_player_count:
	set(value):
		player_count = value
		setup_items()

var extraPing = 0
var unique_string = OS.get_unique_id()

var menu_start_cam: String = "%CamInitial"

var rebind_popup: RebindPopup = null

var menu_ignore_input: bool = false

const MODE1_OFFLINE = 0
const MODE1_ONLINE = 1

const MODE2_RACE = 0
const MODE2_TIMETRIALS = 1
const MODE2_BATTLE = 2
const MODE2_MISSION = 3

var MODE1: int = MODE1_OFFLINE
var MODE2: int = MODE2_RACE

var save_on_exit := true

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
	load("res://scenes/items/Book.tscn"),
	# load("res://scenes/items/RunningShoes/running_shoes.tscn")
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

var heads: Dictionary = {
	"special-week": "res://assets/character/head.tscn",
	"nice-nature": "res://assets/character/_nice-nature/head.tscn"
}

var selected_replay: String = "user://replays/Wicked_Woods/1738524227.sav"
#var selected_replay: String = "user://replays/1test/1738524048.sav"

func _enter_tree() -> void:
	process_mode = PROCESS_MODE_ALWAYS

func setup_items() -> void:
	print("Setting up items...")
	item_dist.clear()
	for _i in range(player_count):
		item_dist.append([])
	
	for item: PackedScene in items:
		var instance = item.instantiate()
		item_tex.append(instance.texture)
		var new_from: int = ceil(remap(instance.from_pos, 1, 12, 1, player_count))
		var new_to: int = ceil(remap(instance.to_pos, 1, 12, 1, player_count))
		print(instance.name, " ", new_from, " ", new_to)
		for i in range(new_from-1, new_to):
			if i < player_count:
				item_dist[i].append(item)
		instance.queue_free()

	UI.race_ui.setup()

#func _ready():
	#var gravity := Vector3(0, -1, 0)
	#var vel := Vector3(1, -1, -1)
	#var wall_normal := Vector3(0, -1, 1).normalized()
	#var on_grav_plane := vel.slide(gravity)
	#var wall_on_grav_plane := wall_normal.slide(gravity)
	#var tmp := on_grav_plane.project(wall_on_grav_plane.normalized())
#
	#print(on_grav_plane)
	#print(wall_on_grav_plane)
	#print(on_grav_plane - tmp)
	#
	#get_tree().quit()
	#setup_items()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await Network.on_exit_async()
		if save_on_exit:
			Config.save_config(Config.make_config())
		get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("_F11") and get_window().has_focus():
		if Config.window_mode > 0:
			Config.window_mode = 0
		else:
			Config.window_mode = 2
		Config.update_config()
	
	# If a rebind popup is active, reroute all relevant input there.
	if rebind_popup:
		if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
			rebind_popup.handle_input(event)
		return
