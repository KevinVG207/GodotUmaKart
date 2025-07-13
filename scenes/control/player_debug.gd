extends Node

class_name PlayerDebug

var enabled: bool = false

func draw(vehicle: Vehicle4) -> void:
	Debug.print(CheckpointManager.get_progress(vehicle))
	
	Debug.pd_clear()
	Debug.item_dist_clear()
	
	if Input.is_action_just_pressed("_F10"):
		enabled = !enabled
	
	if !enabled:
		return
	
	print_vehicle_fields(vehicle)
	print_item_distributions(vehicle)
	return

func print_item_distributions(vehicle: Vehicle4) -> void:
	var dist := Global.make_item_distributions(vehicle)
	
	var tot_weight: float = Util.sum(dist)
	
	for i: int in range(Global.item_distributions.size()):
		Debug.item_dist_print(Util.get_file_name_from_path(Global.item_distributions.keys()[i].get_path()), dist[i]/tot_weight)

func print_vehicle_fields(vehicle: Vehicle4) -> void:
	Debug.pd_print(vehicle.input.to_dict(), "input")
	Debug.pd_print(vehicle.is_player, "is player")
	Debug.pd_print(vehicle.is_cpu, "is cpu")
	Debug.pd_print(vehicle.is_network, "is network")
	Debug.pd_print(vehicle.is_replay, "is replay")
	Debug.pd_print(vehicle.user_id, "user id")
	Debug.pd_print(vehicle.username, "username")
	Debug.pd_print(vehicle.global_position, "glob pos")
	Debug.pd_print(vehicle.global_rotation_degrees, "glob rot deg")
	Debug.pd_print(vehicle.started, "started")
	Debug.pd_print(vehicle.finished, "finished")
	Debug.pd_print(vehicle.check_idx, "check idx")
	Debug.pd_print(vehicle.check_key_idx, "check key idx")
	Debug.pd_print(vehicle.check_progress, "check progress")
	Debug.pd_print(vehicle.cur_progress, "cur progress")
	Debug.pd_print(vehicle.lap, "lap")
	Debug.pd_print(vehicle.rank, "rank")
	Debug.pd_print(vehicle.finish_time, "finish time")
	Debug.pd_print(vehicle.velocity.total(), "velocity total")
	Debug.pd_print(vehicle.velocity.prop_vel, "prop vel")
	Debug.pd_print(vehicle.velocity.rest_vel, "rest vel")
	Debug.pd_print(vehicle.velocity.grav_component(vehicle.gravity), "grav comp")
	Debug.pd_print(vehicle.gravity, "gravity")
	Debug.pd_print(vehicle.air_frames, "air frames")
	Debug.pd_print(vehicle.in_hop, "in hop")
	Debug.pd_print(vehicle.hop_frames, "hop frames")
	Debug.pd_print(vehicle.grounded, "grounded")
	Debug.pd_print(vehicle.is_stick, "is stick")
	Debug.pd_print(vehicle.bounce_frames, "bounce frames")
	Debug.pd_print(vehicle.floor_normal, "floor normal")
	Debug.pd_print(vehicle.cur_speed, "cur speed")
	Debug.pd_print(vehicle.max_speed, "max speed")
	Debug.pd_print(vehicle.grip, "grip")
	Debug.pd_print(vehicle.steering, "steering")
	Debug.pd_print(vehicle.turn_speed, "turn speed")
	Debug.pd_print(vehicle.max_turn_speed, "max turn speed")
	Debug.pd_print(vehicle.turn_accel, "turn accel")
	Debug.pd_print(vehicle.in_drift, "in drift")
	Debug.pd_print(vehicle.drift_dir, "drift dir")
	Debug.pd_print(vehicle.drift_gauge, "drift gauge")
	Debug.pd_print(vehicle.drift_gauge_max, "drift gauge max")
	Debug.pd_print(vehicle.drift_offset, "drift offset")
	Debug.pd_print(vehicle.along_ground_multi, "along ground multi")
	Debug.pd_print(Vehicle4.RespawnStage.keys()[vehicle.respawn_stage], "respawn stage")
	Debug.pd_print(vehicle.cur_boost_type, "cur boost type")
	Debug.pd_print(vehicle.in_trick, "in trick")
	Debug.pd_print(vehicle.trick_boost_type, "trick boost type")
	Debug.pd_print(vehicle.trick_input_frames, "trick input frames")
	Debug.pd_print(vehicle.trick_timer, "trick timer")
	Debug.pd_print(Vehicle4.DamageType.keys()[vehicle.cur_damage_type], "cur damage type")
	Debug.pd_print(Vehicle4.DamageType.keys()[vehicle.do_damage_type], "do damage type")
	Debug.pd_print(vehicle.item, "item")
	Debug.pd_print(vehicle.can_use_item, "can use item")
	Debug.pd_print(vehicle.has_dragged_item, "has dragged item")
	Debug.pd_print(vehicle.active_items, "active items")
	Debug.pd_print(vehicle.is_controlled, "is controlled")
	Debug.pd_print(vehicle.use_cpu_logic, "use cpu logic")
	Debug.pd_print(vehicle.catchup_multi, "catchup multi")
	Debug.pd_print(vehicle.in_rewind, "in rewind")
	Debug.pd_print(vehicle.rewind_start_frame, "rewind start frame")
	Debug.pd_print(vehicle.rewind_frame, "rewind frame")
	Debug.pd_print(vehicle.rewind_data.size(), "rewind data size")
	Debug.pd_print(vehicle.world.pings.get(vehicle.user_id), "ping")
