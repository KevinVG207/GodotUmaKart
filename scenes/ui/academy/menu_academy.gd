extends Node3D

var traveling: bool = false
var travel_time: float = 2.5
@onready var cam: Camera3D = $ActiveCamera
var cam_follow: PathFollow3D
var target_cam: MenuCam

func _ready():
	cam.rotation = $CamInitial.rotation
	cam.global_position = $CamInitial.global_position
	cam.fov = $CamInitial.fov
	$CamInitial.opacity = 1.0

func _process(delta):
	if traveling:
		cam.global_position = cam_follow.global_position
	if not traveling:
		if Input.is_action_just_pressed("F1"):
			start_cam_travel($CamInitial, $CamFountain, $PathInitialFountain/Follow, travel_time, false)
		elif Input.is_action_just_pressed("F2"):
			start_cam_travel($CamFountain, $CamInitial, $PathInitialFountain/Follow, travel_time, true)
		elif Input.is_action_just_pressed("F3"):
			start_cam_travel($CamFountain, $CamSpica, $PathFountainSpica/Follow, travel_time)
		elif Input.is_action_just_pressed("F4"):
			start_cam_travel($CamSpica, $CamFountain, $PathFountainSpica/Follow, travel_time, true)

func start_cam_travel(start_cam: MenuCam, end_cam: MenuCam, path_follow: PathFollow3D, time: float, reverse: bool=false, fade_time: float=-1, wait_fade_start: bool=false, wait_fade_end: bool=false):
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
	tween.tween_property(start_cam, "opacity", 0.0, fade_time).set_delay(fade_delay_start).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(end_cam, "opacity", 1.0, fade_time).set_delay(fade_delay_end + wait_start).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(cam, "rotation", end_cam.rotation, time).set_delay(wait_start).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(cam, "fov", end_cam.fov, time).set_delay(wait_start).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	var end_val = 1.0
	if !reverse:
		path_follow.progress_ratio = 0.0
	else:
		path_follow.progress_ratio = 1.0
		end_val = 0.0
	
	cam_follow = path_follow
	tween.tween_property(path_follow, "progress_ratio", end_val, time).set_delay(wait_start).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.finished.connect(_on_cam_tween_finished)
	target_cam = end_cam
	
func _on_cam_tween_finished():
	traveling = false
