extends CanvasLayer

var water = false
@export var underwater_color: Color
var transparent: Color = Color(0, 0, 0, 0)

@onready var race_ui: RaceUI = $RaceUI

func show_race_ui():
	$RaceUI.visible = true

func apply_water():
	if not water:
		water = true
		var tween = create_tween()
		tween.tween_property($RaceUI/ColorRect, "color", underwater_color, 0.2).set_trans(Tween.TRANS_CUBIC)

func clear_effect():
	water = false
	var tween = create_tween()
	tween.tween_property($RaceUI/ColorRect, "color", transparent, 0.2).set_trans(Tween.TRANS_CUBIC)

func update_ranks(vehicles: Array):
	var rank_strings = []
	for vehicle: Vehicle3 in vehicles:
		rank_strings.append("#" + str(vehicle.rank) + ": " + vehicle.name)
	$RaceUI/Ranks.text = "\n".join(rank_strings)
