extends Node

class_name CPULogic

@export var parent: Vehicle4
var target: EnemyPath = null
var target_offset := get_random_target_offset()

var respawning := false
var progress: float = -100000

func set_inputs() -> void:
	return

func _process(_delta: float) -> void:
	if !respawning and parent.respawn_stage == Vehicle4.RespawnStage.RESPAWNING:
		respawning = true
		target = Util.get_path_point_ahead_of_player(parent)
		target_offset = get_random_target_offset()
	
	if respawning and parent.respawn_stage != Vehicle4.RespawnStage.RESPAWNING:
		respawning = false

	if parent.respawn_stage != Vehicle4.RespawnStage.NONE:
		progress = -100000


func get_random_target_offset() -> Vector3:
	return Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))