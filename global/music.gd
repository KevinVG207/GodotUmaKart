extends Node

var race_music_player := AudioStreamPlayer.new()
var race_music_volume := 0.0
var final_lap := false
const AFTER_RACE_FADEOUT_TIME := 1.0

func _ready() -> void:
	add_child(race_music_player)
	race_music_player.bus = "MUSIC"

func play_race_music(multi_stream: AudioStreamSynchronized, multi: float) -> void:
	final_lap = false
	race_music_player.stream = multi_stream
	race_music_volume = linear_to_db(multi * multi * multi)
	for i: int in range(multi_stream.stream_count):
		multi_stream.set_sync_stream_volume(i, -INF)
	multi_stream.set_sync_stream_volume(0, race_music_volume)
	race_music_player.play()

func start_final_lap(multi: float) -> void:
	if final_lap:
		return
	final_lap = true
	race_music_player.play(0.0)
	race_music_player.pitch_scale = multi

func race_music_stop(instant := false) -> void:
	if instant:
		race_music_player.stop()
	var tween = create_tween()
	tween.tween_property(race_music_player, "volume_linear", 0.0, AFTER_RACE_FADEOUT_TIME) \
	.finished.connect(func(): race_music_player.stop())
