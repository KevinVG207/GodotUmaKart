extends CanvasLayer

class_name RaceUI

signal roulette_ended

@export var info_box_scene: PackedScene
@onready var back_btn: Button = $BackToLobby
@export var nametag_scene: PackedScene

var last_item_texture: CompressedTexture2D = null
var last_rotation: bool = false
var roulette_end: bool = false
var roulette_stop: bool = false

var nametags: Dictionary = {}

func _ready():
	$"ItemBox/Viewport/ItemRoulette".get_node("Item2").texture = Global.item_tex.pick_random()
	$"ItemBox/Viewport/ItemRoulette".get_node("Item1").texture = Global.item_tex.pick_random()
	pass

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

func start_roulette():
	roulette_stop = false
	roulette_end = false
	last_rotation = false
	$ItemBox.visible = true
	$"ItemBox/Viewport".disable_3d = false
	$"ItemBox/Viewport/AnimationPlayer".play("rotate")
	$"ItemBox/Viewport/AnimationPlayer".speed_scale = 2.0

func hide_roulette():
	$ItemBox.visible = false
	$"ItemBox/Viewport".disable_3d = true

func stop_roulette(item_texture: CompressedTexture2D):
	last_item_texture = item_texture
	last_rotation = true
	roulette_end = false
	roulette_stop = false

func set_item_texture(item_texture: CompressedTexture2D):
	$"ItemBox/Viewport/ItemRoulette".get_node("Item1").texture = item_texture

func _on_rotate_end():
	if roulette_stop:
		return
	if roulette_end:
		roulette_stop = true
		$"ItemBox/Viewport/AnimationPlayer".play("RESET")
		roulette_ended.emit()
	
	var tex1 = $"ItemBox/Viewport/ItemRoulette".get_node("Item1").texture
	var tex2 = Global.item_tex.pick_random()
	
	if last_rotation:
		roulette_end = true
		tex2 = last_item_texture
		#$"ItemBox/3DLayer/AnimationPlayer".speed_scale = 1.0
		#$"ItemBox/3DLayer/AnimationPlayer".play("rotate_end")
		var tween = create_tween()
		tween.tween_property($"ItemBox/Viewport/AnimationPlayer", "speed_scale", 1.0, 0.2)
		
	
	$"ItemBox/Viewport/ItemRoulette".get_node("Item2").texture = tex1
	$"ItemBox/Viewport/ItemRoulette".get_node("Item1").texture = tex2
	#$"ItemBox/3DLayer/AnimationPlayer".call_deferred("play", "rotate")

func _on_rotate_true_end():
	roulette_ended.emit()

func update_nametag(user_id: String, username: String, coords: Vector2, opacity: float, dist: float, tag_visible: bool, force: bool, delta: float):
	if not tag_visible:
		opacity = 0.0

	opacity = clamp(opacity, 0, 1.0)
	
	if not user_id in nametags:
		var nt = nametag_scene.instantiate()
		$Nametags.add_child(nt)
		nt.username.text = username
		nt.modulate.a = 0.0
		nametags[user_id] = nt
	
	var cur_nt = nametags[user_id] as Nametag
	cur_nt.position = coords
	cur_nt.dist = dist
	
	if force:
		cur_nt.modulate.a = opacity
	else:
		cur_nt.modulate.a = move_toward(cur_nt.modulate.a, opacity, delta * 3.0)



func sort_nametags():
	var order_list = nametags.keys()
	order_list.sort_custom(func(a, b): return nametags[a].dist > nametags[b].dist)
	for i in range(len(order_list)):
		nametags[order_list[i]].z_index = i
	
