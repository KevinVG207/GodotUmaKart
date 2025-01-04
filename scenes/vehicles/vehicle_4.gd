extends RigidBody3D

class_name Vehicle4

@export var icon: CompressedTexture2D

var tick: int = -1
var delta: float = 1.0 / Engine.physics_ticks_per_second
var visual_delta := delta * 3.0

var sleep := false

var world: RaceBase = null
var physics_state: PhysicsDirectBodyState3D
var prev_transform: Transform3D = Transform3D.IDENTITY

var max_displacement_for_sleep := 0.003
var max_degrees_change_for_sleep := 0.5

@export var base_max_speed: float = 25
var max_speed := base_max_speed
@export var base_initial_accel: float = 10
@export var base_accel_exponent: float = 10
var initial_accel := base_initial_accel
var accel_exponent := base_accel_exponent
@export var reverse_multi := 0.5
var friction_multi := 1.5
@export var base_grip: float = 60
var grip := base_grip

var cur_speed := 0.0

var gravity := Vector3.DOWN * 18
@export var terminal_velocity: float = 3000
var air_frames := 0

var prev_input := VehicleInput.new()
var input := VehicleInput.new()

var is_player := true
var is_cpu := false
var is_network := false
var is_replay := false
var user_id := ""
var username := "Player"

@onready var cpu_logic := %CPULogic

var can_use_item: bool = false

var started := true
var finished := false
var check_idx := -1
var check_key_idx := 0
var check_progress := 0.0
var lap := 0
var rank := 999999
var finish_time := 0.0

var prev_velocity := Velocity.new()
var velocity := Velocity.new()

class Velocity:
	var prop_vel: Vector3
	var rest_vel: Vector3

	func total() -> Vector3:
		return prop_vel + rest_vel
	
	func grav_component(gravity: Vector3) -> Vector3:
		return rest_vel.project(gravity.normalized())


class VehicleInput:
	var accel := false
	var brake := false
	var steer := 0.0
	var trick := false
	var item := false
	var tilt := 0.0
	var mirror := false

var prev_contacts := {}
var contacts := {}
var prev_ground_contacts := []
var ground_contacts := []
var prev_grounded := false
var grounded := false
var floor_normal: Vector3 = Vector3.UP
var below_normals := []
var floor_check_grid: Array = []
var floor_check_distance: float = 1.0
var ground_rot_multi: float = 5.0
var air_rot_multi: float = 1.0
var is_stick := false
var stick_speed: float = 5
var in_hop := false
var hop_force: float = 3.5
var hop_frames := 0
var min_hop_speed := max_speed * 0.33
var in_bounce := false

var in_drift := false
var drift_dir := 0
var drift_gauge: float = 0
var drift_gauge_max: float = 100
@export var drift_gauge_multi: float = 55.0

var still_turbo_charge_time: float = drift_gauge_multi / 36.666
var still_turbo_max_speed: float = 1
var still_turbo_ready: bool = false

var along_ground_multi := 0.0
var along_ground_dec := 5.0
var min_angle_to_detach := 10.0

class Contact:
	var collider: Object
	var position: Vector3
	var normal: Vector3
	var type: ContactType

enum ContactType {
	UNKNOWN,
	FLOOR,
	WALL,
	OFFROAD,
	TRICK,
	BOOST,
	FALL
}

var floor_types := [
	ContactType.UNKNOWN,
	ContactType.FLOOR,
	ContactType.TRICK,
	ContactType.BOOST
	]

class WallContact extends Contact:
	var bounce := 0.2

class OffroadContact extends Contact:
	var speed_multi := 0.5

class TrickContact extends Contact:
	var boost := BoostType.NORMAL

var cur_boost_type: BoostType = BoostType.NONE
@onready var boost_timer: Timer = %BoostTimer
enum BoostType {
	NONE,
	SMALL,
	NORMAL,
	BIG
}

var boosts := {
	BoostType.SMALL: Boost.new(0.6, 1.2, 5, 1),
	BoostType.NORMAL: Boost.new(1.0, 1.4, 5, 1),
	BoostType.BIG: Boost.new(1.5, 1.6, 5, 1)
}
class Boost:
	var length: float
	var speed_multi: float
	var initial_accel_multi: float
	var exponent_multi: float

	func _init(_length: float, _speed_multi: float, _initial_accel_multi: float, _exponent_multi: float) -> void:
		length = _length
		speed_multi = _speed_multi
		initial_accel_multi = _initial_accel_multi
		exponent_multi = _exponent_multi

var in_trick := false
var trick_boost_type: BoostType = BoostType.NONE

var steering := 0.0
@export var max_turn_speed: float = 80.0
@export var steer_speed_decrease: float = 0.025
@export var drift_turn_multiplier: float = 1.2
@export var drift_turn_min_multiplier: float = 0.5
@export var air_turn_multiplier: float = 0.5
var turn_speed := 0.0
@export var base_turn_accel: float = 1800
var turn_accel := base_turn_accel

var replay_transparency := 0.75
var standard_colliders: Array = []

var trick_safezone_frames := 36
var trick_input_frames := 0
var trick_timer := 0
var trick_timer_length := int(180 * 0.4)

var visual_event_queue := []

func _ready() -> void:
	# UI.show_race_ui()
	setup_floor_check_grid()
	setup_head()
	setup_colliders()
	
	if is_replay:
		recursive_set_transparency($Visual)

func setup_colliders() -> void:
	for child: Node in get_children():
		if child is CollisionShape3D:
			standard_colliders.append(child)

func recursive_set_transparency(n: Node) -> void:
	if n is GeometryInstance3D:
		n.transparency = replay_transparency
		n.cast_shadow = false
	
	for c: Node in n.get_children():
		recursive_set_transparency(c)

func setup_head() -> void:
	$Visual/Character/Body.get_node("%Head").add_child(Util.get_random_head())

func setup_floor_check_grid() -> void:
	var fl: Vector3 = %FrontLeft.position
	var fr: Vector3 = %FrontRight.position
	var bl: Vector3 = %BackLeft.position
	var br: Vector3 = %BackRight.position
	var ml: Vector3 = fl.lerp(bl, 0.5)
	var mr: Vector3 = fr.lerp(br, 0.5)
	
	floor_check_grid = [
		fl, fl.lerp(fr, 0.5), fr,
		ml, ml.lerp(mr, 0.5), mr,
		bl, bl.lerp(br, 0.5), br
	]

func _process(_delta: float) -> void:
	UI.race_ui.update_speed(cur_speed)

	while visual_event_queue.size() > 0:
		var event: Callable = visual_event_queue.pop_at(0)
		event.call()
	
	handle_particles()
	
	if is_player:
		Debug.print([check_idx, check_progress])

func handle_particles() -> void:
	handle_drift_particles()
	handle_exhaust_particles()

func handle_exhaust_particles() -> void:
	Util.multi_emit(%ExhaustIdle, false)
	Util.multi_emit(%ExhaustBoost, false)
	
	if cur_boost_type != BoostType.NONE:
		Util.multi_emit(%ExhaustBoost, true)
		return
	Util.multi_emit(%ExhaustIdle, true)


func handle_drift_particles() -> void:
	Util.multi_emit(%DriftCenterCharging, false)
	Util.multi_emit(%DriftCenterCharged, false)
	Util.multi_emit(%DriftLeftCharging, false)
	Util.multi_emit(%DriftLeftCharged, false)
	Util.multi_emit(%DriftRightCharging, false)
	Util.multi_emit(%DriftRightCharged, false)
	
	if in_drift:
		if drift_gauge >= drift_gauge_max:
			if drift_dir > 0:
				Util.multi_emit(%DriftLeftCharged, true)
			else:
				Util.multi_emit(%DriftRightCharged, true)
		else:
			if drift_dir > 0:
				Util.multi_emit(%DriftLeftCharging, true)
			else:
				Util.multi_emit(%DriftRightCharging, true)
	elif !%StillTurboTimer.is_stopped():
		Util.multi_emit(%DriftCenterCharging, true)
	elif still_turbo_ready:
		Util.multi_emit(%DriftCenterCharged, true)

func visual_tick() -> void:
	set_inputs()

func _integrate_forces(new_physics_state: PhysicsDirectBodyState3D) -> void:
	physics_state = new_physics_state
	tick += 1
	delta = new_physics_state.step
	visual_delta += delta

	handle_sleep()

	if tick % 3 == 0:
		visual_tick()
		visual_delta = 0.0

	respawn_if_too_low()

	detect_collisions()

	handle_item()

	handle_steer()

	apply_velocities()

	apply_rotations()

	prev_transform = transform
	return

func handle_sleep() -> void:
	sleep = false
	if !is_network and velocity.prop_vel.length() < 0.01 and prev_transform.origin.distance_to(transform.origin) < max_displacement_for_sleep and prev_transform.basis.x.angle_to(transform.basis.x) < max_degrees_change_for_sleep and prev_transform.basis.y.angle_to(transform.basis.y) < max_degrees_change_for_sleep and prev_transform.basis.z.angle_to(transform.basis.z) < max_degrees_change_for_sleep:
		transform = prev_transform
		sleep = true

func respawn_if_too_low() -> void:
	if global_position.y < -100:
		respawn()

func respawn() -> void:
	return

func set_inputs() -> void:
	prev_input = input
	input = VehicleInput.new()

	# if !started:
	# 	return

	# if finished:
	# 	return

	if is_cpu:
		cpu_logic.set_inputs()
		return
	
	input.accel = Input.is_action_pressed("accelerate")
	input.brake = Input.is_action_pressed("brake") or Input.is_action_pressed("brake2")
	input.steer = Input.get_axis("right", "left")
	input.trick = Input.is_action_pressed("trick")
	input.item = Input.is_action_pressed("item")
	input.tilt = Input.get_axis("down", "up")
	input.mirror = Input.is_action_pressed("mirror")
	return


func detect_collisions() -> void:
	set_col_layer()

	handle_vehicle_collisions()

	build_contacts()

	determine_grounded()
	determine_stick()
	determine_max_speed_and_accel()
	
	if grounded:
		air_frames = 0
	else:
		air_frames += 1

	determine_floor_normal()
	return

func determine_grounded() -> void:
	prev_grounded = grounded
	grounded = !ground_contacts.is_empty()
	return

func determine_stick() -> void:
	is_stick = false
	if air_frames < 15 and !in_bounce:
		var ray_origin := transform.origin
		var ray_end := ray_origin + gravity.normalized() * 1.4
		# TODO: Change this back
		var ray_result := world.space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 0xFFFFFFFF, [self]))

		if ray_result:
			is_stick = true
			grounded = true
			# keep_grav = true

func determine_max_speed_and_accel() -> void:
	if in_hop and air_frames < 30:
		return
	max_speed = base_max_speed
	initial_accel = base_initial_accel
	accel_exponent = base_accel_exponent
	grip = base_grip
	apply_offroad_speed_multi()
	apply_boost_speed_multi()
	apply_turn_speed_reduction()
	return

func apply_offroad_speed_multi() -> void:
	if ContactType.OFFROAD not in contacts:
		return
	
	var speed_multi := 1.0
	for contact: OffroadContact in contacts[ContactType.OFFROAD]:
		if contact.speed_multi < speed_multi:
			speed_multi = contact.speed_multi
	
	max_speed *= speed_multi
	grip *= 0.5
	return

func apply_boost_speed_multi() -> void:
	if cur_boost_type == BoostType.NONE:
		return
	
	var cur_boost: Boost = boosts[cur_boost_type]
	max_speed *= cur_boost.speed_multi
	initial_accel *= cur_boost.initial_accel_multi
	accel_exponent *= cur_boost.exponent_multi

func apply_turn_speed_reduction() -> void:
	max_speed -= abs(turn_speed) * steer_speed_decrease
	return

func determine_floor_normal() -> void:
	if !ground_contacts:
		return
	
	raycast_below()

	var normals := below_normals
	if normals.is_empty():
		# Naive floor normal detection
		for contact: Contact in ground_contacts:
			normals.append(contact.normal)
	
	if normals.is_empty():
		return

	floor_normal = Util.sum(normals) / normals.size()
	return

func raycast_below() -> void:
	below_normals = []

	for loc_start_pos: Vector3 in floor_check_grid:
		var start_pos := to_global(loc_start_pos)
		var end_pos := start_pos + (transform.basis.y.normalized() * -floor_check_distance)
		# TODO: Revert
		var result := Util.raycast_for_group(world.space_state, start_pos, end_pos, "floor", [self])
		if result:
			below_normals.append(result.normal)


func set_col_layer() -> void:
	if !is_player:
		set_collision_layer_value(2, false)
		set_collision_layer_value(3, true)
	else:
		set_collision_layer_value(2, true)
		set_collision_layer_value(3, false)

func handle_vehicle_collisions() -> void:
	expire_vehicle_collisions()
	build_vehicle_collisions()

func expire_vehicle_collisions() -> void:
	return

func build_vehicle_collisions() -> void:
	return

func build_contacts() -> void:
	prev_contacts = contacts
	contacts = {}
	prev_ground_contacts = ground_contacts
	ground_contacts = []

	for i in range(physics_state.get_contact_count()):
		var cur_ground_contact := false
		var collider := physics_state.get_contact_collider_object(i) as Node3D
		var groups := collider.get_groups()
		if groups.is_empty():
			groups.append("UNKNOWN")
		for group_raw in groups:
			var group_str := str(group_raw).to_upper()
			if group_str.begins_with("_"):
				continue

			var split_settings := group_str.split("_")
			var type_str := split_settings[0]
			var settings := split_settings.slice(0,0) if split_settings.size() == 1 else split_settings.slice(1)

			if type_str not in ContactType:
				continue

			var contact_type: ContactType = ContactType[type_str]
			if contact_type in floor_types:
				cur_ground_contact = true
			
			var contact: Contact = null

			match contact_type:
				ContactType.WALL:
					contact = WallContact.new()
					if collider.get("physics_material_override") and collider.physics_material_override.get("bounce"):
						contact.bounce = collider.physics_material_override.bounce
				ContactType.OFFROAD:
					contact = OffroadContact.new()
					if !settings.is_empty():
						match settings[0]:
							"WEAK":
								contact.speed_multi = 0.75
							"STRONG":
								contact.speed_multi = 0.35
				ContactType.BOOST:
					apply_boost(BoostType.NORMAL)
				ContactType.TRICK:
					contact = TrickContact.new()
					if !settings.is_empty():
						match settings[0]:
							"BIG":
								contact.boost = BoostType.BIG
							"SMALL":
								contact.boost = BoostType.SMALL
			
			if contact == null:
				contact = Contact.new()

			contact.collider = collider
			contact.position = physics_state.get_contact_local_position(i)
			contact.normal = physics_state.get_contact_local_normal(i)
			contact.type = contact_type

			if contact_type not in contacts:
				contacts[contact_type] = []

			contacts[contact_type].append(contact)
		
		if cur_ground_contact:
			var contact := Contact.new()
			contact.collider = collider
			contact.position = physics_state.get_contact_local_position(i)
			contact.normal = physics_state.get_contact_local_normal(i)
			contact.type = ContactType.FLOOR
			ground_contacts.append(contact)
	return

func apply_boost(boost_type: BoostType) -> void:
	if boost_type < cur_boost_type:
		return
	cur_boost_type = boost_type
	boost_timer.start(boosts[boost_type].length)

func handle_item() -> void:
	return

func handle_steer() -> void:
	angular_velocity = Vector3.ZERO
	steering = 0.0
	turn_accel = base_turn_accel

	# if respawn_stage:
	# 	return

	steering = clampf(input.steer, -1.0, 1.0)

	# TODO: Drift
	if in_drift:
		steering = drift_dir * remap(steering * drift_dir, -1, 1, drift_turn_min_multiplier, drift_turn_multiplier)

	var cur_max_turn_speed: float = 0.5/(2*max(0.001, cur_speed)+1) + max_turn_speed
	var turn_target := steering * cur_max_turn_speed

	turn_speed = move_toward(turn_speed, turn_target, turn_accel * delta)

	var multi := 1.0 if grounded else air_turn_multiplier
	transform.basis = transform.basis.rotated(transform.basis.y, deg_to_rad(turn_speed * delta * multi))
	return

func apply_velocities() -> void:
	prev_velocity = velocity
	velocity = Velocity.new()
	velocity.prop_vel = prev_velocity.prop_vel
	velocity.rest_vel = prev_velocity.rest_vel

	collide_vehicles()
	collide_walls()

	handle_trick()
	handle_hop()
	handle_drift()

	handle_standstill_turbo()

	apply_gravity()

	stick_to_ground()

	apply_acceleration()
	velocity.prop_vel = transform.basis.z.normalized() * cur_speed

	rotate_accel_along_floor()

	outside_drift_force()

	linear_velocity = velocity.total()
	return

func collide_vehicles() -> void:
	return

func collide_walls() -> void:
	# Bounce of all walls?
	# Reduce speed to minimum after all contacts?
	return

func handle_trick() -> void:
	trick_input_frames = maxi(trick_input_frames - 1, 0)
	trick_timer = maxi(trick_timer - 1, 0)

	if input.trick:
		trick_input_frames = trick_safezone_frames
	
	if ContactType.TRICK in prev_contacts and !ground_contacts:
		# Trick can begin
		trick_timer = trick_timer_length
		for contact: TrickContact in prev_contacts[ContactType.TRICK]:
			if contact.boost > trick_boost_type:
				trick_boost_type = contact.boost
	
	if trick_input_frames and trick_timer:
		trick_input_frames = 0
		trick_timer = 0
		in_trick = true
		start_hop()
	
	if ground_contacts and in_trick and hop_frames > 30:
		in_trick = false
		trick_boost_type = BoostType.NONE
		apply_boost(BoostType.NORMAL)

func handle_hop() -> void:
	min_hop_speed = max_speed * 0.6
	if !in_hop and input.accel and input.brake and !prev_input.brake and cur_speed > min_hop_speed:
		# Perform hop
		start_hop()

	if in_hop:
		hop_frames += 1

		if air_frames and hop_frames < 2:
			if in_trick:
				hop_frames = 4
			else:
				hop_frames = 30

		if hop_frames < 9:
			velocity.rest_vel += -gravity * 0.03
			is_stick = false
		
		if input.steer != 0 and drift_dir == 0 and hop_frames > 30:
			drift_dir = 1 if input.steer > 0 else -1

		if hop_frames > 30 and ground_contacts:
			in_hop = false
			if input.brake and cur_speed > min_hop_speed and drift_dir != 0:
				in_drift = true
				drift_gauge = 0
	return

func start_hop() -> void:
	if in_hop:
		return
	in_hop = true
	hop_frames = -1
	return

func handle_drift() -> void:
	if !in_drift:
		return
	
	if cur_speed < min_hop_speed:
		in_drift = false
		drift_dir = 0
	
	if !(input.brake and input.accel):
		in_drift = false
		drift_dir = 0
		if input.accel and drift_gauge >= drift_gauge_max:
			apply_boost(BoostType.SMALL)
		return
	
	drift_gauge += remap(abs(steering), drift_turn_min_multiplier, drift_turn_multiplier, 1, 2) * drift_gauge_multi * delta
	drift_gauge = clampf(drift_gauge, 0, drift_gauge_max)
	return

func handle_standstill_turbo() -> void:
	if prev_input.brake and !input.brake:
		%StillTurboTimer.stop()
		if still_turbo_ready:
			still_turbo_ready = false
			apply_boost(BoostType.SMALL)

func stick_to_ground() -> void:
	if !is_stick:
		return
	
	velocity.rest_vel += -transform.basis.y.project(gravity.normalized()) * gravity.length() * delta
	return

func apply_gravity() -> void:
	var grav_component := velocity.grav_component(gravity)
	if ground_contacts and grav_component.normalized().dot(gravity.normalized()) > 0:
		velocity.rest_vel -= grav_component
		# velocity.rest_vel += gravity / 10
	
	# if prev_grounded and !grounded:
	# 	velocity.rest_vel += gravity / 4

	velocity.rest_vel += gravity * delta

	grav_component = velocity.grav_component(gravity)
	if grav_component.length() >= terminal_velocity:
		velocity.rest_vel -= grav_component
		velocity.rest_vel += gravity.normalized() * terminal_velocity

func apply_acceleration() -> void:
	if !grounded:
		return

	var speed_delta: float = 0.0
	if input.accel and input.brake and !in_hop and !in_drift and cur_boost_type == BoostType.NONE:
		if abs(cur_speed) <= still_turbo_max_speed:
			speed_delta = get_standstill_turbo_speed()
			start_standstill_turbo()
		elif cur_speed > 0:
			speed_delta = get_brake_speed()
		else:
			speed_delta = get_accel_speed()
	elif input.accel or cur_boost_type != BoostType.NONE:
		speed_delta = get_accel_speed()
	elif input.brake:
		speed_delta = get_reverse_speed()
	else:
		speed_delta = get_friction_speed()
	
	var new_speed := clampf(cur_speed + speed_delta * delta, -max_speed, max_speed)
	cur_speed = move_toward(cur_speed, new_speed, delta * grip)

func start_standstill_turbo() -> void:
	if grounded and not still_turbo_ready and %StillTurboTimer.is_stopped():
		%StillTurboTimer.start(still_turbo_charge_time)

func rotate_accel_along_floor() -> void:
	# TODO: This might not be the correct angle?
	# Rotate the propulsion direction
	if grounded and !prev_grounded:
		# We were in the air and have now landed
		along_ground_multi = 1.0
	
	var angle_z := velocity.prop_vel.normalized().angle_to(floor_normal)
	var angle_to_ground := 90 - rad_to_deg(angle_z)
	
	var new_prop_vel := velocity.prop_vel.rotated(transform.basis.x, deg_to_rad(angle_to_ground))
	velocity.prop_vel = velocity.prop_vel.normalized().slerp(new_prop_vel.normalized(), along_ground_multi) * velocity.prop_vel.length()

	along_ground_multi -= along_ground_dec * delta
	along_ground_multi = clamp(along_ground_multi, 0.0, 1.0)
	return

func outside_drift_force() -> void:
	return

func get_standstill_turbo_speed() -> float:
	var mult := -1.0

	if cur_speed < 0:
		mult = 1.0

	return Util.get_vehicle_accel(max_speed, abs(abs(cur_speed) - max_speed), initial_accel, accel_exponent) * mult
func get_accel_speed() -> float:
	if cur_speed < 0:
		return -get_brake_speed()
	
	return Util.get_vehicle_accel(max_speed, cur_speed, initial_accel, accel_exponent)

func get_brake_speed() -> float:
	return initial_accel * -2

func get_reverse_speed() -> float:
	if cur_speed > 0:
		return get_brake_speed()
	
	return -Util.get_vehicle_accel(max_speed * reverse_multi, -cur_speed, initial_accel * reverse_multi, accel_exponent)

func get_friction_speed() -> float:
	var mult := 1.0 if cur_speed < 0 else -1.0
	return mult * Util.get_vehicle_accel(max_speed, abs(abs(cur_speed) - max_speed), initial_accel * friction_multi, accel_exponent)

func apply_rotations() -> void:
	rotate_stick()
	rotate_to_gravity()

func rotate_stick() -> void:
	if !grounded:
		return
	
	# # Rotate the vehicle to match the ground.
	# var multi := 0.1

	# if below_normals:
	# 	multi = float(len(below_normals)) / len(floor_check_grid)

	var tmp := transform
	look_at(global_position + floor_normal, -global_transform.basis.z.normalized(), true)
	var rotated_transform := global_transform.rotated(global_transform.basis.x.normalized(), 0.5*PI)
	transform = tmp
	global_transform.basis = Basis(global_transform.basis.get_rotation_quaternion().slerp(rotated_transform.basis.get_rotation_quaternion(), delta * ground_rot_multi))

func rotate_to_gravity() -> void:
	if grounded:
		return

	var tmp := transform
	look_at(global_position - gravity, -global_transform.basis.z.normalized(), true)
	var rotated_transform := global_transform.rotated(global_transform.basis.x.normalized(), 0.5*PI)
	transform = tmp
	global_transform.basis = Basis(global_transform.basis.get_rotation_quaternion().slerp(rotated_transform.basis.get_rotation_quaternion(), delta * air_rot_multi))

func stop_movement() -> void:
	prev_transform = transform
	prev_velocity = Velocity.new()
	velocity = prev_velocity
	cur_speed = 0
	turn_speed = 0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func teleport(new_pos: Vector3, look_dir: Vector3, up_dir: Vector3, keep_velocity: bool = true) -> void:
	global_position = new_pos
	look_at(new_pos + look_dir, up_dir, true)
	if !keep_velocity:
		stop_movement()

func axis_lock() -> void:
	axis_lock_linear_x = true
	axis_lock_linear_z = true

func axis_unlock() -> void:
	axis_lock_linear_x = false
	axis_lock_linear_z = false

func initialize_player() -> void:
	is_player = true
	is_cpu = false
	is_network = false
	is_replay = false
	UI.race_ui.roulette_ended.connect(_on_roulette_stop)

func set_rank(new_rank: int) -> void:
	if is_player and new_rank != rank:
		UI.race_ui.update_rank(new_rank)
	rank = new_rank

func _on_boost_timer_timeout() -> void:
	cur_boost_type = BoostType.NONE


func _on_still_turbo_timer_timeout() -> void:
	still_turbo_ready = true

func _on_roulette_stop() -> void:
	can_use_item = true
