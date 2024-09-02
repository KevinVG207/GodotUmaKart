extends Node3D

class_name MenuAcademy

var traveling: bool = false
var travel_time: float = 2.5
@onready var cam: Camera3D = $ActiveCamera
var cam_follow: PathFollow3D
var from_cam: MenuCam
@onready var to_cam: MenuCam = %CamInitial

var charas_spawned := false
var no_map_charas: int = 50

var map_character_scene: PackedScene = preload("res://scenes/ui/academy/map_character.tscn")

func _ready() -> void:
	Engine.physics_ticks_per_second = 120
	hide_cams()
	%EETimer.start(564)
	
	to_cam = get_node(Global.menu_start_cam)
	
	if to_cam == %CamTrunk:
		Global.goto_lobby_screen.emit()
	
	cam.rotation = to_cam.rotation
	cam.global_position = to_cam.global_position
	cam.fov = to_cam.fov
	to_cam.opacity = 1.0
	to_cam.visible = true


func hide_cams():
	for camera: MenuCam in $Menus.get_children():
		camera.visible = false
		#camera.click_area.input_ray_pickable = false

func _process(delta):
	if !charas_spawned:
		charas_spawned = true
		for i in range(no_map_charas):
			var instance: MapCharacter = map_character_scene.instantiate()
			$Characters.add_child(instance)
			instance.global_position = NavigationServer3D.map_get_random_point($NavigationRegion3D.get_navigation_map(), 1, true)
			#instance.global_position += Vector3.UP * 100.0
	
	if traveling:
		cam.global_position = cam_follow.global_position
	if not traveling:
		if Input.is_action_just_pressed("_F1"):
			title_to_fountain()
		elif Input.is_action_just_pressed("_F2"):
			fountain_to_title()
		elif Input.is_action_just_pressed("_F3"):
			start_cam_travel(%CamFountain, %CamSpica, $PathFountainSpica/Follow, travel_time)
		elif Input.is_action_just_pressed("_F4"):
			start_cam_travel(%CamSpica, %CamFountain, $PathFountainSpica/Follow, travel_time, true)

func start_cam_travel(start_cam: MenuCam, end_cam: MenuCam, path_follow: PathFollow3D, time: float, reverse: bool=false, fade_time: float=-1, wait_fade_start: bool=false, wait_fade_end: bool=false):
	if traveling:
		return

	traveling = true
	if fade_time < 0:
		fade_time = time/2
	
	var wait_start: float = 0.0
	
	var fade_delay_start: float = 0.0
	var fade_delay_end: float = (time - fade_time)/2
	
	if wait_fade_start:
		wait_start = fade_time
	if wait_fade_end:
		fade_delay_end = time
	
	var tween: Tween = create_tween().set_parallel(true)
	start_cam.opacity = 1.0
	end_cam.opacity = 0.0
	cam.rotation = start_cam.rotation
	cam.fov = start_cam.fov
	
	hide_cams()
	start_cam.visible = true
	end_cam.visible = true
	tween.tween_property(start_cam, "opacity", 0.0, fade_time).set_delay(fade_delay_start).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(end_cam, "opacity", 1.0, fade_time).set_delay(fade_delay_end + wait_start).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(cam, "rotation", end_cam.rotation, time).set_delay(wait_start).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(cam, "fov", end_cam.fov, time).set_delay(wait_start).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	var callback = func():
		#end_cam.click_area.input_ray_pickable = true
		end_cam.focus()
	tween.tween_callback(callback).set_delay(fade_delay_end + wait_start)
	
	var end_val = 1.0
	if !reverse:
		path_follow.progress_ratio = 0.0
	else:
		path_follow.progress_ratio = 1.0
		end_val = 0.0
	
	cam_follow = path_follow
	tween.tween_property(path_follow, "progress_ratio", end_val, time).set_delay(wait_start).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.finished.connect(_on_cam_tween_finished)
	from_cam = start_cam
	to_cam = end_cam
	
func fountain_to_title():
	start_cam_travel(%CamFountain, %CamInitial, $PathInitialFountain/Follow, travel_time, true)
	%EETimer.start(564)

func title_to_fountain():
	%EETimer.stop()
	start_cam_travel(%CamInitial, %CamFountain, $PathInitialFountain/Follow, travel_time)

func fountain_to_trunk():
	Global.goto_lobby_screen.emit()
	start_cam_travel(%CamFountain, %CamTrunk, $PathFountainTrunk/Follow, travel_time/2)

func trunk_to_fountain():
	start_cam_travel(%CamTrunk, %CamFountain, $PathFountainTrunk/Follow, travel_time/2, true)

func fountain_to_spica():
	Global.goto_settings_screen.emit()
	start_cam_travel(%CamFountain, %CamSpica, $PathFountainSpica/Follow, travel_time)

func spica_to_fountain():
	start_cam_travel(%CamSpica, %CamFountain, $PathFountainSpica/Follow, travel_time, true)


func _on_cam_tween_finished():
	cam.global_position = cam_follow.global_position
	cam.rotation = to_cam.rotation
	cam.fov = to_cam.fov
	from_cam.visible = false
	to_cam.has_focus()
	traveling = false

func _input(event: InputEvent):
	if to_cam == %CamInitial and !traveling:
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
			title_to_fountain()
			return
	#print(event)
	
	if !traveling:
		if "position" in event:
			event.position *= to_cam.scale_multi
		if "global_position" in event:
			event.global_position *= to_cam.scale_multi
		to_cam.viewport.push_input(event)


func _on_ee_timer_timeout():
	$Menus/CamInitial/SubViewport/CamInitialMenu/PressKey.text = "PRESS_ANY2"


func _on_lobby_back() -> void:
	trunk_to_fountain()

func _on_cam_fountain_menu_to_settings() -> void:
	fountain_to_spica()

func _on_cam_spica_menu_back() -> void:
	spica_to_fountain()

func _on_cam_fountain_menu_to_title() -> void:
	fountain_to_title()

func _on_cam_fountain_menu_to_lobby() -> void:
	fountain_to_trunk()
