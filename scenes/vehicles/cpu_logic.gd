extends Node

class_name CPULogic

@export var parent: Vehicle4
var target: EnemyPath = null
var target_offset := get_random_target_offset()
var target_pos := Vector3.ZERO

var respawning := false
var progress: float = -100000
var moved_to_next := false

func set_inputs() -> void:
	# if parent.in_damage:
	# 	return
	
	if not target:
		return
	
	if !parent.started:
		return

	update_target()
	
	if !parent.is_network:
		try_trick()
		accel_decel()

	steer()

	# if parent.is_being_controlled:
	# 	parent.input.brake = false

	# if !parent.is_network:
	# 	try_use_item()
	
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

func update_target() -> void:
	target_pos = target.global_position + (target_offset * target.dist / 3)
	if parent.global_position.distance_to(target_pos) < target.dist or Util.dist_to_plane(target.normal, target.global_position, parent.global_position) > 0:
		# Get next target
		target = parent.world.pick_next_path_point(target)
		target_offset = get_random_target_offset()
		moved_to_next = true
		update_target()

func try_trick() -> void:
	if !parent.trick_timer:
		return
	
	if parent.is_controlled:
		return

	var chance := float(parent.trick_timer_length - parent.trick_timer) / parent.trick_timer_length / (Engine.physics_ticks_per_second / 20.0)
	if randf() < (chance):
		parent.input.trick = true
	if parent.grounded and parent.cur_speed > parent.min_hop_speed and randf() < (1.0 / Engine.physics_ticks_per_second):
		parent.input.brake = true

func accel_decel() -> void:
	parent.input.accel = true
	return

func steer() -> void:
	var target_dir := get_target_dir()
	var angle := get_angle_to_target(target_dir)
	var max_angle := get_max_angle_to_target()

	var is_behind := parent.transform.basis.z.dot(target_dir) < 0

	if is_behind:
		if angle < 0:
			angle -= 10
		else:
			angle += 10
	
	# if !parent.is_network:
	hold_drift(angle)
	
	if abs(angle) > max_angle:
		# Should steer
		parent.input.steer = -1 if angle < 0 else 1
		if !parent.is_network:
			try_release_drift()


func hold_drift(angle: float) -> void:
	if abs(angle) > 0.5 and parent.cur_speed > parent.min_hop_speed and randf() < (2.0 / Engine.physics_ticks_per_second):
		parent.input.brake = true
	
	if (parent.in_drift or parent.in_hop or parent.air_frames > Engine.physics_ticks_per_second/4.0) and (parent.drift_gauge >= 75 or abs(angle) > 0.2):
		parent.input.brake = true

func try_release_drift() -> void:
	if parent.input.steer * parent.drift_dir < 0 and parent.in_drift and (parent.drift_gauge <= 80 or parent.drift_gauge == 100):
		parent.input.brake = false

func get_target_dir() -> Vector3:
	return (target_pos - parent.global_position).normalized()

func get_angle_to_target(target_dir: Vector3) -> float:
	return (-parent.global_transform.basis.x).angle_to(target_dir) - PI/2
func get_max_angle_to_target() -> float:
	return target.dist/2 / parent.global_position.distance_to(target_pos)
