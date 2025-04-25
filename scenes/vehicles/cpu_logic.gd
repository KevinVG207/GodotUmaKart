extends Node

class_name CPULogic

@export var parent: Vehicle4
# var target: EnemyPath = null
# var target_offset := get_random_target_offset()
# var target_pos := Vector3.ZERO

var respawning := false
var progress: float = -100000
var moved_to_next := false

var network: NetworkPlayer

var rubber_band_range: float = 100
var rubber_band_minimum := 0.75
var rubber_band_maximum := 1.5
var prev_rubber_band_multi := 1.0

var speed_multi := 1.0
var turn_speed_multi := 1.0

static var failsafe_seconds: float = 10
var failsafe_tick_max: int = 0
var failsafe_tick: int = 0
var failsafe_start_progress: float = -1000

var next_target_1: EnemyPath = null
var next_target_2: EnemyPath = null
var target_2_offset: Vector3
var curve: Curve3D = null
var curve_point_position: Vector3 = Vector3.ZERO
var curve_point_forward: Vector3 = Vector3.ZERO
var natural_start_point: Vector3
const CURVE_SAMPLE_DISTANCE: float = 10.0
const CURVE_SAMPLE_OFFSET: float = 0.05

func _ready() -> void:
	network = parent.network
	failsafe_tick_max = int(failsafe_seconds * Engine.physics_ticks_per_second)

func set_inputs(delta: float) -> void:
	# if parent.in_damage:
	# 	return
	
	if not next_target_1:
		return
	
	if not next_target_2:
		new_target(next_target_1)

	do_rubberband(delta)

	# return

	update_target()
	update_curve_point()
	
	if !parent.is_network:
		try_trick()
		accel_decel()
	else:
		parent.input.accel = parent.prev_input.accel
		parent.input.brake = parent.prev_input.brake

	if !parent.started:
		return

	steer()

	# if parent.is_being_controlled:
	# 	parent.input.brake = false

	if !parent.is_network:
		try_use_item()
	
	return

func _process(_delta: float) -> void:
	if !respawning and parent.respawn_stage == Vehicle4.RespawnStage.RESPAWNING:
		respawning = true
		new_target(Util.get_path_point_ahead_of_player(parent))
		# target = Util.get_path_point_ahead_of_player(parent)
		# target_offset = get_random_target_offset()
	
	if respawning and parent.respawn_stage != Vehicle4.RespawnStage.RESPAWNING:
		respawning = false

	if parent.respawn_stage != Vehicle4.RespawnStage.NONE:
		progress = -100000

func do_rubberband(delta: float) -> void:
	speed_multi = 1.0
	turn_speed_multi = 1.0

	if parent.cur_boost_type != Vehicle4.BoostType.NONE:
		prev_rubber_band_multi = 1.0
		return
	
	if parent.is_controlled:
		prev_rubber_band_multi = 1.0
		return

	# TODO: Use "race distance" instead of checkpoints. Checkpoint system will have to be reworked
	# Each checkpoint should have a distance value.
	var dist_to_player := parent.global_position.distance_to(parent.world.player_vehicle.global_position)
	var no_checkpoints_between := parent.world.checkpoints_between_players(parent, parent.world.player_vehicle)

	if dist_to_player < rubber_band_range:
		prev_rubber_band_multi = 1.0
		return
	
	# var rubberband_multi = clampf(remap(no_checkpoints_between, -10, 10, rubber_band_maximum, rubber_band_minimum), rubber_band_minimum, rubber_band_maximum)
	var rubberband_multi := 1.0
	if no_checkpoints_between < 0:
		rubberband_multi = remap(no_checkpoints_between, -10, 0, rubber_band_maximum, 1.0)
	else:
		rubberband_multi = remap(no_checkpoints_between, 0, 10, 1.0, rubber_band_minimum)
	rubberband_multi = clampf(rubberband_multi, rubber_band_minimum, rubber_band_maximum)
	if rubberband_multi < prev_rubber_band_multi:
		rubberband_multi = move_toward(prev_rubber_band_multi, rubberband_multi, delta * 0.5)
	
	prev_rubber_band_multi = rubberband_multi
	speed_multi = rubberband_multi
	turn_speed_multi = maxf(1.0, remap(rubberband_multi, 1.0, rubber_band_maximum, 1.0, rubber_band_maximum * 1.2))

	# if no_checkpoints_between >= 0:
	# 	do_rubberband_slow(no_checkpoints_between)
	# else:
	# 	do_rubberband_fast(no_checkpoints_between)

func get_random_target_offset(radius:float=1.0) -> Vector3:
	return Vector3(randf_range(-radius, radius), randf_range(-radius, radius), randf_range(-radius, radius))

func update_target() -> void:
	if passed_target(next_target_1):
		new_target(next_target_2, true)
	return

func new_target(target: EnemyPath, natural: bool = false) -> void:
	if target == null:
		return
	
	next_target_1 = target
	next_target_2 = parent.world.pick_next_path_point(next_target_1)

	new_curve(natural)

func passed_target(target: EnemyPath) -> bool:
	if target == null:
		return false
	
	if parent.global_position.distance_to(target.global_position) < target.radius:
		return true
	
	if Util.dist_to_plane(target.global_basis.z, target.global_position, parent.global_position) >= 0:
		return true
	
	return false

func new_curve(natural: bool = false) -> void:
	var in1 := next_target_1.get_in_vector()
	var out1 := next_target_1.get_out_vector()
	var in2 := next_target_2.get_in_vector()

	var start_point := parent.global_position
	if natural and natural_start_point:
		start_point = natural_start_point
	
	var offset1 := target_2_offset if target_2_offset != Vector3.ZERO else get_random_target_offset(next_target_1.radius)
	var offset2 := get_random_target_offset(next_target_2.radius)
	natural_start_point = next_target_1.global_position + offset1
	target_2_offset = offset2

	in1 *= minf(1.0, parent.global_position.distance_to(next_target_1.global_position) / next_target_1.radius)

	curve = RaceUtil.make_curve_double(
		start_point,
		natural_start_point,
		next_target_2.global_position + offset2,
		Vector3.ZERO,
		in1,
		out1,
		in2
	)

func update_curve_point() -> void:
	if parent.is_network and !moved_to_next:
		curve_point_position = next_target_1.global_position
		curve_point_forward = next_target_1.normal
		return

	var curve_sample_distance := 20.0
	curve_sample_distance = clampf(curve_sample_distance * (parent.cur_speed / parent.max_speed), 3, curve_sample_distance)
	var curve_current_distance := curve.get_closest_offset(parent.global_position) + curve_sample_distance

	if curve_current_distance + CURVE_SAMPLE_OFFSET > curve.get_baked_length():
		curve_current_distance = curve.get_baked_length() - CURVE_SAMPLE_OFFSET

	var p1 := curve.sample_baked(curve_current_distance - CURVE_SAMPLE_OFFSET)
	var p2 := curve.sample_baked(curve_current_distance + CURVE_SAMPLE_OFFSET)
	curve_point_position = (p1 + p2) * 0.5
	curve_point_forward = (p2 - p1).normalized()

func passed_curve_point() -> bool:
	return Util.dist_to_plane(curve_point_forward, curve_point_position, parent.global_position) >= 0

func try_trick() -> void:
	if !parent.trick_timer:
		return
	
	if parent.is_controlled:
		return

	var chance := float(parent.trick_timer_length - parent.trick_timer) / parent.trick_timer_length / (Engine.physics_ticks_per_second / 20.0)
	if randf() < (chance):
		parent.input.trick = true
	if parent.grounded and parent.cur_speed > parent.min_hop_speed and randf() < (1.0 / Engine.physics_ticks_per_second / 3.0):
		parent.input.brake = true

func accel_decel() -> void:
	if parent.started:
		parent.input.accel = true
		return
	
	if parent.prev_input.accel:
		parent.input.accel = true
		return

	if parent.world.countdown_timer * parent.world.PHYSICS_TICKS_PER_SECOND < parent.countdown_timer and randf() < 0.01:
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
	
	if !parent.is_network:
		hold_drift(angle)
	
	if abs(angle) > max_angle:
		# Should steer
		parent.input.steer = -1 if angle < 0 else 1
		if !parent.is_network:
			try_release_drift()


func hold_drift(angle: float) -> void:
	if abs(angle) > 0.2 and parent.cur_speed > parent.min_hop_speed: # and randf() < (2.0 / Engine.physics_ticks_per_second):
		parent.input.brake = true
	
	if !parent.input.brake and abs(angle) > 0.3 and parent.cur_speed > parent.min_hop_speed and randf() < (1.0 / (Engine.physics_ticks_per_second * 0.2)):
		parent.input.brake = true
	
	if (parent.in_drift or parent.in_hop or parent.air_frames > Engine.physics_ticks_per_second/4.0) and parent.drift_gauge < 100:
		parent.input.brake = true

func try_release_drift() -> void:
	if parent.input.steer * parent.drift_dir < 0 and parent.in_drift and (parent.drift_gauge <= 80 or parent.drift_gauge == 100):
		parent.input.brake = false

func get_target_dir() -> Vector3:
	return (curve_point_position - parent.global_position).normalized()

func get_angle_to_target(target_dir: Vector3) -> float:
	return (-parent.global_transform.basis.x).angle_to(target_dir) - PI/2
func get_max_angle_to_target() -> float:
	return next_target_1.radius*0.25 / parent.global_position.distance_to(next_target_1.global_position)


func try_use_item() -> void:
	var perform := true if randf() < 1.0/(Engine.physics_ticks_per_second / 3.0) else false

	if parent.has_dragged_item:
		perform_draggable_item(perform)
		return
	
	if parent.item == null:
		return

	var item: Node = parent.item
	if item.is_in_group("item_draggable"):
		perform_draggable_item(perform)
		return

	perform_default_item(perform)
	return
	
func perform_draggable_item(perform: bool) -> void:
	if !perform and !parent.has_dragged_item:
		# Ignore
		return
	
	if perform and !parent.has_dragged_item:
		# Start dragging
		parent.input.item = true
		return
	
	if parent.has_dragged_item and perform and randf() < 0.25:
		# Throw
		parent.input.item = false
		return
	
	# Keep dragging
	parent.input.item = true


func perform_default_item(perform: bool) -> void:
	if perform:
		perform = true if randf() < 0.25 else false
	parent.input.item = perform
	return

func handle_failsafe_timer() -> void:
	if !parent.is_cpu or !parent.started:
		failsafe_tick = 0
		return
	
	if parent.respawn_stage != Vehicle4.RespawnStage.NONE:
		failsafe_tick = 0
		return

	if failsafe_tick == 0:
		failsafe_start_progress = parent.cur_progress

	var diff: float = parent.cur_progress - failsafe_start_progress

	if diff > 0.5:
		failsafe_tick = 0
		return
	
	failsafe_tick += 1

	if failsafe_tick > failsafe_tick_max:
		parent.respawn()
