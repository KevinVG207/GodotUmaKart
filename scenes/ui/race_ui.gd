extends CanvasLayer

class_name RaceUI

signal roulette_ended

@export var info_box_scene: PackedScene
@onready var back_btn: Button = $BackToLobby
@export var nametag_scene: PackedScene
#@export var icon_material: ShaderMaterial
#@export var icon_material_player: ShaderMaterial

var last_item_texture: CompressedTexture2D = null
var last_rotation: bool = false
var roulette_end: bool = false
var roulette_stop: bool = false
@onready var map_viewport: SubViewport = $MapContainer/MapTexture/MapViewport
var map_camera: Camera3D
@onready var map_texture: TextureRect = $MapContainer/MapTexture
@onready var startline_marker: Sprite2D = $MapContainer/StartLineMarker
@onready var player_icons_node: Node = $MapContainer/PlayerIcons

var nametags: Dictionary = {}
var player_icons: Dictionary = {}

func _ready():
	$"ItemBox/Viewport/ItemRoulette".get_node("Item2").texture = Global.item_tex.pick_random()
	$"ItemBox/Viewport/ItemRoulette".get_node("Item1").texture = Global.item_tex.pick_random()
	pass

func update_icons(players: Array):
	for icon: Sprite2D in player_icons.values():
		icon.visible = false
	
	for player: Vehicle3 in players:
		var id: String = player.user_id
		
		# Create new icons
		if not id in player_icons:
			var new_icon = Sprite2D.new()
			new_icon.scale = Vector2(0.3, 0.3)
			new_icon.texture = player.icon
			if player.is_player:
				#new_icon.material = icon_material_player
				pass
			else:
				#new_icon.material = icon_material
				new_icon.modulate.a = 0.4
			player_icons_node.add_child(new_icon)
			player_icons[id] = new_icon
		
		var icon: Sprite2D = player_icons[id]
		icon.z_index = len(players) - player.rank
		if player.is_player:
			icon.z_index += len(players)
		icon.visible = true
		move_map_sprite(icon, player.global_position)
		

func set_map_camera(cam: Camera3D):
	cam.reparent(map_viewport)
	map_camera = cam

func set_startline(checkpoint: Checkpoint):
	var global_pos = checkpoint.to_global(checkpoint.position)
	var global_forward = global_pos + checkpoint.transform.basis.z
	var local_pos = map_camera.to_local(global_pos)
	var local_forward = map_camera.to_local(global_forward)
	var local_dir = local_forward - local_pos
	var canvas_dir: Vector2 = Vector2(local_dir.x, -local_dir.y).normalized()
	move_map_sprite(startline_marker, checkpoint.global_position, canvas_dir)

func move_map_sprite(sprite: Sprite2D, global_pos: Vector3, direction: Vector2 = Vector2.RIGHT):
	var viewport_pos: Vector2 = map_camera.unproject_position(global_pos)
	var final_x = viewport_pos.x / map_viewport.size.x * map_texture.size.x + map_texture.position.x
	var final_y = viewport_pos.y / map_viewport.size.y * map_texture.size.y + map_texture.position.y
	sprite.position = Vector2(final_x, final_y)
	sprite.look_at(sprite.position + direction.rotated(PI/2))

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
	#$Username.visible = true

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
	cur_nt.username.text = username
	
	if force:
		cur_nt.modulate.a = opacity
	else:
		cur_nt.modulate.a = move_toward(cur_nt.modulate.a, opacity, delta * 3.0)



func sort_nametags():
	var order_list = nametags.keys()
	order_list.sort_custom(func(a, b): return nametags[a].dist > nametags[b].dist)
	for i in range(len(order_list)):
		nametags[order_list[i]].z_index = i
	

func remove_nametag(user_id: String):
	if user_id in nametags:
		var nt = nametags[user_id]
		nametags.erase(user_id)
		nt.queue_free()
