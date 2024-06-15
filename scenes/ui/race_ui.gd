extends Control

class_name RaceUI

var item_tex = {
	"1carrot": load("res://assets/items/1carrot.png"),
	"2carrots": load("res://assets/items/2carrots.png"),
	"3carrots": load("res://assets/items/3carrots.png")
}

@export var info_box_scene: PackedScene
@onready var back_btn: Button = $BackToLobby

func _ready():
	$"ItemBox/3DLayer/AnimationPlayer".play("rotate")

func update_speed(speed):
	$Speed.text = str(int(speed))

func update_countdown(cd):
	$Countdown.text = str(cd)

func set_max_laps(laps):
	$LapCountContainer/MarginContainer/MaxLaps.text = "/%d" % int(max(laps, 1))

func set_cur_lap(lap):
	$LapCountContainer/CurLap.text = tr("RACE_LAP") % int(max(lap, 1))

func finished():
	$Finished.visible = true

func race_over():
	$RaceOver.visible = true

func enable_spectating():
	$Spectating.visible = true
	$Username.visible = true

func set_username(usr: String):
	$Username.text = usr

func update_time(time: float):
	$Time.text = Util.format_time_ms(time)

func hide_time():
	$Time.visible = false

func update_timeleft(time: float):
	$TimeLeft.text = Util.format_time_minutes(time)

func show_back_btn():
	$BackToLobby.disabled = false
	$BackToLobby.visible = true


func _on_rotate_end():
	print("next")
	var tex1 = $"ItemBox/3DLayer/ItemRoulette".get_node("Item1").texture
	var tex2 = item_tex.values().pick_random()
	$"ItemBox/3DLayer/ItemRoulette".get_node("Item2").texture = tex1
	$"ItemBox/3DLayer/ItemRoulette".get_node("Item1").texture = tex2
	#$"ItemBox/3DLayer/AnimationPlayer".call_deferred("play", "rotate")
