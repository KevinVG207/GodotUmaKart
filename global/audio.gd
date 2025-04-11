extends Node

var ui_player := AudioStreamPlayer.new()
var sfx_player := AudioStreamPlayer.new()

var race_music_player := AudioStreamPlayer.new()
var race_music_volume := 0.0
var final_lap := false
const AFTER_RACE_FADEOUT_TIME := 1.0

@onready var countdown_normal_sound: AudioStreamWAV = preload("res://assets/audio/race/countdown/countdown.wav")
@onready var countdown_go_sound: AudioStreamWAV = preload("res://assets/audio/race/countdown/go.wav")
@onready var final_lap_sound: AudioStreamWAV = preload("res://assets/audio/race/final-lap.wav")

func _ready() -> void:
	add_child(ui_player)
	add_child(sfx_player)
	add_child(race_music_player)
	ui_player.bus = "UI"
	ui_player.max_polyphony = 10
	sfx_player.bus = "SFX"
	sfx_player.max_polyphony = 10
	race_music_player.bus = "MUSIC"

func play_race_music(multi_stream: AudioStreamSynchronized, multi: float) -> void:
	play_countdown_go()
	
	final_lap = false
	race_music_player.stop()
	race_music_player.stream = multi_stream
	race_music_volume = linear_to_db(multi * multi * multi)
	for i: int in range(multi_stream.stream_count):
		multi_stream.set_sync_stream_volume(i, -INF)
	multi_stream.set_sync_stream_volume(0, race_music_volume)
	get_tree().create_timer(0.5).timeout.connect(func():
		race_music_player.play()
	)

func start_final_lap(multi: float) -> void:
	if final_lap:
		return
	final_lap = true
	race_music_player.stop()
	race_music_player.pitch_scale = multi
	play_final_lap_sound()
	
	get_tree().create_timer(1.0).timeout.connect(func():
		race_music_player.play(0.0)
	)

func race_music_stop(instant := false) -> void:
	if instant:
		race_music_player.stop()
	var tween = create_tween()
	tween.tween_property(race_music_player, "volume_linear", 0.0, AFTER_RACE_FADEOUT_TIME) \
	.finished.connect(func(): race_music_player.stop())

func play_countdown_normal() -> void:
	sfx_player.stream = countdown_normal_sound
	sfx_player.play(0)

func play_countdown_go() -> void:
	sfx_player.stream = countdown_go_sound
	sfx_player.play(0)

func play_final_lap_sound() -> void:
	sfx_player.stream = final_lap_sound
	sfx_player.play(0)
