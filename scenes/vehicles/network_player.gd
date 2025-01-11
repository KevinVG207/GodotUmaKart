extends Node

class_name NetworkPlayer

@onready var vehicle: Vehicle4 = get_parent()

var network_teleport_distance: float = 25.0

var prev_state: Dictionary = {}
var prev_input: Vehicle4.VehicleInput = null

var packet_idx := -1
# var prev_state: Dictionary = get_state()

func get_state() -> Dictionary:
	packet_idx += 1
	return {
		# Easy things
		"idx": packet_idx,
		"vani": vehicle.vani.animation,
		"cur_speed": vehicle.cur_speed,
		"turn_speed": vehicle.turn_speed,
		"in_trick": vehicle.in_trick,
		"in_hop": vehicle.in_hop,
		"hop_frames": vehicle.hop_frames,
		"air_frames": vehicle.air_frames,
		"in_drift": vehicle.in_drift,
		"drift_dir": vehicle.drift_dir,
		"drift_gauge": vehicle.drift_gauge,
		"grounded": vehicle.grounded,
		"in_bounce": vehicle.in_bounce,
		"bounce_frames": vehicle.bounce_frames,
		# "in_water": vehicle.in_water,
		"respawn_stage": vehicle.respawn_stage,
		"check_idx": vehicle.check_idx,
		"check_key_idx": vehicle.check_key_idx,
		"check_progress": vehicle.check_progress,
		"lap": vehicle.lap,
		"finished": vehicle.finished,
		"finish_time": vehicle.finish_time,
		"username": vehicle.username,
		"boost_type": vehicle.cur_boost_type,
		"still_turbo_ready": vehicle.still_turbo_ready,

		# Special
		"gravity": Util.to_array(vehicle.gravity),
		"pos": Util.to_array(vehicle.global_position),
		"rot": Util.quat_to_array(vehicle.quaternion),
		"velocity": vehicle.velocity.to_dict(),
		"input": vehicle.input.to_dict(),
		"respawn_time": vehicle.respawn_timer.time_left,
		"boost_time": vehicle.boost_timer.time_left,
		"still_turbo_time": vehicle.still_timer.time_left,
	}

func apply_state(state: Dictionary) -> void:
	if packet_idx > state.idx:
		return

	prev_state = state
	prev_input = Vehicle4.VehicleInput.from_dict(state.input)

	packet_idx = state.idx

	if state.in_hop:
		vehicle.start_hop()
	if state.in_drift and !vehicle.in_drift and !state.in_hop:
		vehicle.start_hop()

	apply_simple(state)

	vehicle.gravity = Util.to_vector3(state.gravity)
	vehicle.velocity = Vehicle4.Velocity.from_dict(state.velocity)
	vehicle.input = Vehicle4.VehicleInput.from_dict(state.input)

	set_path_point(state)

	# FIXME: In reality, it should probably compare to the predicted position, because the network_pos is currently behind the true position of the player!
	# BUT the network predicted position could be inside the ground or similar...
	if should_teleport_to_network(Util.to_vector3(state.pos)):
		teleport_to_network(state)
	
	apply_timer(vehicle.respawn_timer, state.respawn_time)
	apply_timer(vehicle.boost_timer, state.boost_time)
	apply_timer(vehicle.still_timer, state.still_turbo_time)

func apply_simple(state: Dictionary) -> void:
	vehicle.vani.animation = state.vani
	vehicle.cur_speed = state.cur_speed
	vehicle.turn_speed = state.turn_speed
	vehicle.in_trick = state.in_trick
	vehicle.air_frames = state.air_frames
	vehicle.in_drift = state.in_drift
	vehicle.drift_dir = state.drift_dir
	vehicle.drift_gauge = state.drift_gauge
	vehicle.grounded = state.grounded
	vehicle.in_bounce = state.in_bounce
	vehicle.bounce_frames = state.bounce_frames
	vehicle.respawn_stage = state.respawn_stage
	vehicle.finished = state.finished
	vehicle.finish_time = state.finish_time
	vehicle.username = state.username
	vehicle.cur_boost_type = state.boost_type
	vehicle.still_turbo_ready = state.still_turbo_ready

func set_path_point(state: Dictionary) -> void:
	var network_path := vehicle.world.network_path_points[vehicle] as EnemyPath
	vehicle.cpu_logic.target = network_path
	network_path.global_position = Util.to_vector3(state.pos)
	network_path.quaternion = Util.array_to_quat(state.rot)
	network_path.normal = network_path.transform.basis.z
	if vehicle.user_id in vehicle.world.pings:
		network_path.global_position += network_path.transform.basis.z * state.cur_speed * (1 + ((vehicle.world.pings[vehicle.user_id] + vehicle.world.pings[vehicle.world.player_user_id])/1000)) * 0.35
	# network_path.next_points = [Util.get_path_point_ahead_of_player(vehicle)]
	# network_path.prev_points = network_path.next_points[0].prev_points
	vehicle.cpu_logic.target_offset = Vector3.ZERO
	vehicle.cpu_logic.moved_to_next = false

func teleport_to_network(state: Dictionary) -> void:
		vehicle.global_position = Util.to_vector3(state.pos)
		vehicle.quaternion = Util.array_to_quat(state.rot)
		vehicle.check_idx = state.check_idx
		vehicle.check_key_idx = state.check_key_idx
		vehicle.check_progress = state.check_progress
		vehicle.in_hop = state.in_hop
		vehicle.hop_frames = state.hop_frames
		vehicle.teleport(vehicle.global_position, vehicle.transform.basis.z, vehicle.transform.basis.y)

func should_teleport_to_network(network_pos: Vector3) -> bool:
	if vehicle.global_position.distance_to(network_pos) > network_teleport_distance:
		return true
		
	var grav_component := (vehicle.global_position - network_pos).project(vehicle.gravity)
	if grav_component.length() > network_teleport_distance / 3:
		return true
	return false

func apply_timer(timer: Timer, time_left: float) -> void:
	if time_left <= 0:
		timer.stop()
		return
	timer.start(time_left)
