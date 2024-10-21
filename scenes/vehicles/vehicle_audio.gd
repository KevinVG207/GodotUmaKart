extends Node3D

var our_volume: float = 0.5
var their_volume: float = 0.4
var cur_volume_multi: float = 0

@onready var parent: Vehicle3 = get_parent().get_parent()
@onready var engine_playback: AudioStreamPlaybackPolyphonic
@export var engine_sound: AudioStream
var engine_stream: int
@export var engine_idle_sound: AudioStream
var engine_idle_stream: int

var def_max_distance: float = 100

func _ready() -> void:
	engine_playback = %EngineSFX.get_stream_playback()
	engine_stream = engine_playback.play_stream(engine_sound, randf(), -80, 1.0, AudioServer.PLAYBACK_TYPE_STREAM, "SFX")
	engine_idle_stream = engine_playback.play_stream(engine_idle_sound, randf(), -80, 1.0, AudioServer.PLAYBACK_TYPE_STREAM, "SFX")

func _process(delta: float) -> void:
	do_determine_who()
	do_engine_sound()

func do_determine_who() -> void:
	var max_distance: float = def_max_distance
	var tracking: int = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	cur_volume_multi = their_volume
	
	if parent.is_player:
		max_distance = 0.0
		tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
		cur_volume_multi = our_volume
	
	%EngineSFX.max_distance = max_distance
	%EngineSFX.doppler_tracking = tracking

func do_engine_sound() -> void:
	var engine_idle_volume: float = linear_to_db(cur_volume_multi * clamp(remap(abs(parent.cur_speed), 3, 10, 0.5, 0), 0, 1))
	engine_playback.set_stream_volume(engine_idle_stream, engine_idle_volume)
	
	var engine_volume: float = linear_to_db(cur_volume_multi * clamp(remap(abs(parent.cur_speed), 3, 10, 0.75, 1), 0, 1))
	engine_playback.set_stream_volume(engine_stream, engine_volume)
	
	var engine_pitch: float = remap(abs(parent.cur_speed), 0, parent.default_max_speed, 1.0, 2.0)
	engine_playback.set_stream_pitch_scale(engine_stream, engine_pitch)
