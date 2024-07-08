extends Node3D

var traveling: bool = false
var travel_time: float = 2.5
@onready var cam: Camera3D = $ActiveCamera
var cam_follow: PathFollow3D

func _ready():
	cam.rotation = $CamInitial.rotation
	cam.global_position = $CamInitial.global_position
	cam.fov = $CamInitial.fov

func _process(delta):
	if traveling:
		cam.global_position = cam_follow.global_position
	if not traveling:
		if Input.is_action_just_pressed("F1"):
			start_cam_travel($CamFountain, $PathInitialFountain/Follow, travel_time)
		elif Input.is_action_just_pressed("F2"):
			start_cam_travel($CamSpica, $PathFountainSpica/Follow, travel_time)
		elif Input.is_action_just_pressed("F3"):
			start_cam_travel($CamFountain, $PathFountainSpica/Follow, travel_time, true)

func start_cam_travel(end_cam: Camera3D, path_follow: PathFollow3D, time: float, reverse: bool=false):
	traveling = true
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(cam, "rotation", end_cam.rotation, time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(cam, "fov", end_cam.fov, time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	var end_val = 1.0
	if !reverse:
		path_follow.progress_ratio = 0.0
	else:
		path_follow.progress_ratio = 1.0
		end_val = 0.0
	
	cam_follow = path_follow
	tween.tween_property(path_follow, "progress_ratio", end_val, time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.finished.connect(_on_cam_tween_finished)
	
func _on_cam_tween_finished():
	traveling = false
