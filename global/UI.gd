extends CanvasLayer

var water = false
@export var underwater_color: Color
var transparent: Color = Color(0, 0, 0, 0)

var race_ui_scene: PackedScene = preload("res://scenes/ui/race_ui.tscn")
@onready var race_ui: RaceUI = $RaceUI

func show_race_ui():
	race_ui.visible = true
	
func reset_race_ui():
	race_ui.visible = false
	race_ui.queue_free()
	var new_race_ui = race_ui_scene.instantiate()
	add_child(new_race_ui)
	race_ui = new_race_ui

func apply_water():
	if not water:
		water = true
		var tween = create_tween()
		tween.tween_property(race_ui.get_node("ColorRect"), "color", underwater_color, 0.2).set_trans(Tween.TRANS_CUBIC)

func clear_effect():
	water = false
	var tween = create_tween()
	tween.tween_property(race_ui.get_node("ColorRect"), "color", transparent, 0.2).set_trans(Tween.TRANS_CUBIC)

func update_ranks(vehicles: Array):
	var rank_strings = []
	for vehicle: Vehicle3 in vehicles:
		rank_strings.append("#" + str(vehicle.rank) + ": " + vehicle.username)
	race_ui.get_node("Ranks").text = "\n".join(rank_strings)
