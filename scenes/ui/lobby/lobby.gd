extends Control

@export var info_box: PackedScene
var info_boxes: Dictionary = {}
@onready var box_container: GridContainer = $MarginContainer/PlayerInfoContainer

var count = 0

func _ready():
	add_player("TestUser1", "1")
	add_player("TestUser2", "2")
	add_player("TestUser3", "3")
	add_player("TestUser4", "4")
	add_player("TestUser5", "5")

func _physics_process(_delta):
	count += 1
	if count > 5 * 60:
		remove_player("2")


func add_player(username: String, user_id: String):
	if user_id in info_boxes:
		return
	
	var new_box = info_box.instantiate() as LobbyPlayerInfoBox
	new_box.get_node("Label").text = username
	info_boxes[user_id] = new_box
	box_container.add_child(new_box)


func remove_player(user_id: String):
	if not user_id in info_boxes:
		return
	var cur_box = info_boxes[user_id] as LobbyPlayerInfoBox
	box_container.remove_child(cur_box)
	info_boxes.erase(user_id)
	cur_box.queue_free()
