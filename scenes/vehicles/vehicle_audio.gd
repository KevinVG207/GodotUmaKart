extends Node3D

var our_volume: float = 0.5
var their_volume: float = 0.4
var cur_volume_multi: float = 0

@onready var parent: Vehicle3 = get_parent().get_parent()
@onready var cam: PlayerCam

var occlusion_multi := 1.0
var occlusion_effect_speed := 1.5

var doppler := false
var doppler_multi := 1.0
var doppler_prev_distance: float

var prev_drift_status := DRIFT_NONE
var drift_status := DRIFT_NONE
const DRIFT_NONE := 0
const DRIFT_BUILDING := 1
const DRIFT_STANDSTILL := 2
const DRIFT_FULL := 3

@onready var engine_playback: AudioStreamPlaybackPolyphonic

@export var engine_sound: AudioStream
var engine_stream: int

@export var engine_idle_sound: AudioStream
var engine_idle_stream: int

@export var skid_sound: AudioStream
var skid_stream: int = -1

var spark_sound: AudioStream = preload("res://assets/audio/sfx/vehicle/spark.wav")

var water_splash_sound: AudioStream = preload("res://assets/audio/sfx/splash.wav")

var land_sound: AudioStream = preload("res://assets/audio/sfx/vehicle/land.wav")
var prev_grounded := true

var def_max_distance: float = 100

var setup: bool = false
var cam_switch: bool = true

func _ready() -> void:
	Global.camera_switched.connect(_on_cam_switch)
	engine_playback = %EngineSFX.get_stream_playback()
	engine_stream = engine_playback.play_stream(engine_sound, randf(), -80, 1.0, AudioServer.PLAYBACK_TYPE_STREAM, "SFX")
	engine_idle_stream = engine_playback.play_stream(engine_idle_sound, randf(), -80, 1.0, AudioServer.PLAYBACK_TYPE_STREAM, "SFX")
	

func do_setup() -> bool:
	if parent.world == null:
		return false
	
	if parent.world.player_camera == null:
		return false
	
	cam = parent.world.player_camera
	doppler_prev_distance = cam.global_position.distance_to(global_position)
	return true

func _process(delta: float) -> void:
	if !setup:
		setup = do_setup()
		return
	
	do_determine_who()
	do_occlusion(delta)
	do_doppler(delta)
	do_engine_sound()
	do_drift_sound()
	do_drift_spark_sound()
	do_collision_sound()

func do_determine_who() -> void:
	var max_distance: float = def_max_distance
	doppler = true
	cur_volume_multi = their_volume
	
	if parent.is_player:
		max_distance = 0.0
		doppler = false
		cur_volume_multi = our_volume
	
	%EngineSFX.max_distance = max_distance

func do_drift_spark_sound() -> void:
	drift_status = DRIFT_NONE
	
	if !parent.get_node("StillTurboTimer").is_stopped() or (parent.in_drift and parent.drift_gauge < parent.drift_gauge_max):
		drift_status = DRIFT_BUILDING
	elif parent.still_turbo_ready:
		drift_status = DRIFT_STANDSTILL
	elif parent.drift_gauge >= parent.drift_gauge_max:
		drift_status = DRIFT_FULL
	
	if drift_status == prev_drift_status or drift_status == DRIFT_NONE:
		prev_drift_status = drift_status
		return
	
	prev_drift_status = drift_status
	
	var volume := 0.3
	var pitch := 1.0
	match drift_status:
		DRIFT_BUILDING:
			volume = 0.3
			pitch = 1.0
		DRIFT_STANDSTILL, DRIFT_FULL:
			volume = 0.5
			pitch = 1.2
	
	play_sample(spark_sound, volume, pitch)

func do_occlusion(delta):
	var occlusion_target := 1.0
	
	# Ignore parent
	if parent != parent.world.player_scene:
		var ray_start = global_position
		var ray_end = cam.global_position
		var result = parent.world.space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_start, ray_end, 1))
		if result:
			occlusion_target = 0.5
	
	occlusion_multi = move_toward(occlusion_multi, occlusion_target, delta * occlusion_effect_speed)
	#print("occlusion ", occlusion_target, " ", occlusion_multi)
	

func do_doppler(delta) -> void:
	var doppler_cur_distance = cam.global_position.distance_to(global_position)
	
	doppler_multi = 1.0
	
	if doppler:
		if !cam_switch:
			var dist_delta: float = (doppler_prev_distance - doppler_cur_distance) * delta
			doppler_multi = Util.doppler_sigmoid(dist_delta, 0.075)
		else:
			cam_switch = false
	
	doppler_prev_distance = doppler_cur_distance


func do_engine_sound() -> void:
	var engine_idle_volume: float = make_volume(remap(abs(parent.cur_speed), 3, 10, 0.3, 0))
	if !parent.engine_sound:
		engine_idle_volume = make_volume(0)
	engine_playback.set_stream_volume(engine_idle_stream, engine_idle_volume)
	engine_playback.set_stream_pitch_scale(engine_idle_stream, doppler_multi)
	
	var engine_volume: float = make_volume(remap(abs(parent.cur_speed), 3, 10, 0.5, 0.75))
	if !parent.engine_sound:
		engine_volume = make_volume(0)
	engine_playback.set_stream_volume(engine_stream, engine_volume)
	
	var engine_pitch: float = remap(abs(parent.cur_speed), 0, parent.default_max_speed, 1.0, 2.0)
	engine_pitch *= doppler_multi
	engine_playback.set_stream_pitch_scale(engine_stream, engine_pitch)


func do_drift_sound() -> void:
	if !parent.grounded or (!parent.in_drift and parent.get_node("StillTurboTimer").is_stopped() and !parent.still_turbo_ready):
		if skid_stream >= 0:
			engine_playback.stop_stream(skid_stream)
			skid_stream = -1
		return
	
	# parent is drifting
	if skid_stream == -1:
		skid_stream = engine_playback.play_stream(skid_sound, 0, make_volume(0.1), 1.0, AudioServer.PLAYBACK_TYPE_STREAM, "SFX")
	
	var turn_delta: float = abs(parent.cur_turn_speed) / parent.max_turn_speed
	var turn_pitch_multi: float = clamp(remap(turn_delta, parent.drift_turn_min_multiplier, parent.drift_turn_multiplier, 0, 1), 0, 1)
	turn_pitch_multi = remap(turn_pitch_multi, 0, 1, 0.95, 1.05) * doppler_multi
	engine_playback.set_stream_pitch_scale(skid_stream, turn_pitch_multi)

func do_collision_sound() -> void:
	do_landing_sound()

func do_landing_sound() -> void:
	if !prev_grounded and parent.grounded:
		#var grav_component = parent.prev_frame_pre_sim_vel.project(-parent.floor_normal.normalized())
		#var volume: float = clamp(remap(grav_component.length(), 0, 1, 0, 1), 0.4, 0.75)
		#print("land ", volume, " ", grav_component.length())
		play_sample(land_sound, 0.5, 1.0)
	prev_grounded = parent.grounded

func water_entered() -> void:
	play_sample(water_splash_sound, 0.2, randf_range(1.1, 1.3))

func play_sample(sound: AudioStream, volume_linear: float = 1.0, pitch: float = 1.0, offset: float = 0.0) -> void:
	engine_playback.play_stream(sound, offset, make_volume(volume_linear), pitch, AudioServer.PLAYBACK_TYPE_DEFAULT, "SFX")

func make_volume(linear_volume: float) -> float:
	return linear_to_db(cur_volume_multi * occlusion_multi * clamp(linear_volume, 0, 1))

func _on_cam_switch() -> void:
	cam_switch = true
