extends CanvasLayer

var water = false
@export var underwater_color: Color
var transparent: Color = Color(0, 0, 0, 0)

func update_speed(speed):
	$RaceUI.update_speed(speed)

func apply_water():
	if not water:
		water = true
		var tween = create_tween()
		tween.tween_property($RaceUI/ColorRect, "color", underwater_color, 0.2).set_trans(Tween.TRANS_CUBIC)

func clear_effect():
	water = false
	var tween = create_tween()
	tween.tween_property($RaceUI/ColorRect, "color", transparent, 0.2).set_trans(Tween.TRANS_CUBIC)
