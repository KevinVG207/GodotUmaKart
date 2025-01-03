extends RigidBody3D

class_name Vehicle4

var tick: int = -1
var delta: float = 1.0 / Engine.physics_ticks_per_second
var visual_delta := delta * 3.0

var sleep := false
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

var gravity := Vector3.DOWN * 20
@export var terminal_velocity: float = 3000
var air_frames := 0

var prev_input := VehicleInput.new()
var input := VehicleInput.new()

var is_player := true
var is_cpu := false
var is_network := false

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
var ground_contacts := []
var prev_grounded := false
var grounded := false
var floor_normal: Vector3 = Vector3.UP
var below_normals := []
var floor_check_grid: Array = []
var floor_check_distance: float = 0.8
var ground_rot_multi: float = 6.0
var air_rot_multi: float = 1.0
var is_stick := false
var stick_speed: float = 10
var in_hop := false
var in_bounce := false

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
	var speed_multi := 0.6

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


var steering := 0.0
@export var max_turn_speed: float = 80.0
@export var drift_turn_multiplier: float = 1.2
@export var drift_turn_min_multiplier: float = 0.5
@export var air_turn_multiplier: float = 0.5
var turn_speed := 0.0
@export var base_turn_accel: float = 1800
var turn_accel := base_turn_accel

var visual_event_queue := []

func _ready() -> void:
	UI.show_race_ui()
	print(ContactType.keys())
	setup_floor_check_grid()

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

func visual_tick() -> void:
	while visual_event_queue.size() > 0:
		var event: Callable = visual_event_queue.pop_at(0)
		event.call()
	
	set_inputs()
	handle_particles()

func handle_particles() -> void:
	return

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
		%CPU.set_inputs()
		return
	
	input.accel = Input.is_action_pressed("accelerate")
	input.brake = Input.is_action_pressed("brake") or Input.is_action_pressed("brake2")
	input.steer = Input.get_axis("right", "left")
	input.trick = Input.is_action_just_pressed("trick")
	input.item = Input.is_action_pressed("item")
	input.tilt = Input.get_axis("down", "up")
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
	if air_frames < 15 and !in_hop and !in_bounce:
		var ray_origin := transform.origin
		var ray_end := ray_origin + gravity.normalized() * 1.4
		# TODO: Change this back
		# var ray_result := world.space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 0xFFFFFFFF, [self]))
		var ray_result := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 0xFFFFFFFF, [self]))

		if ray_result:
			is_stick = true
			grounded = true
			# keep_grav = true

func determine_max_speed_and_accel() -> void:
	max_speed = base_max_speed
	initial_accel = base_initial_accel
	accel_exponent = base_accel_exponent
	grip = base_grip
	apply_offroad_speed_multi()
	apply_boost_speed_multi()
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
		# var result := Util.raycast_for_group(world.space_state, start_pos, end_pos, "floor", [self])
		var result := Util.raycast_for_group(get_world_3d().direct_space_state, start_pos, end_pos, "floor", [self])
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
	ground_contacts = []

	for i in range(physics_state.get_contact_count()):
		var cur_ground_contact := false
		var collider := physics_state.get_contact_collider_object(i) as Node3D
		for group_raw in collider.get_groups():
			var group_str := str(group_raw).to_upper()
			if group_str.begins_with("_"):
				continue

			var split_settings := group_str.split("_")
			var type_str := split_settings[0]
			var settings := split_settings.slice(0,0) if split_settings.size() == 1 else split_settings.slice(1)

			var contact_type: ContactType = ContactType[type_str] if type_str in ContactType else ContactType.UNKNOWN
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
								contact.speed_multi *= 0.8
							"STRONG":
								contact.speed_multi *= 0.5
				ContactType.BOOST:
					apply_boost(BoostType.NORMAL)
			
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
	if boost_type <= cur_boost_type:
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

	var cur_max_turn_speed: float = 0.5/(2*max(0.001, cur_speed)+1) + max_turn_speed
	var turn_target := steering * cur_max_turn_speed

	turn_speed = move_toward(turn_speed, turn_target, turn_accel * delta)

	var multi := 1.0 if grounded else air_turn_multiplier
	print(multi)
	rotation_degrees.y += turn_speed * delta * multi
	return

func apply_velocities() -> void:
	prev_velocity = velocity
	velocity = Velocity.new()
	velocity.prop_vel = prev_velocity.prop_vel
	velocity.rest_vel = prev_velocity.rest_vel

	collide_vehicles()
	collide_walls()

	handle_hop()

	apply_gravity()

	stick_to_ground()

	apply_acceleration()
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

func handle_hop() -> void:
	return

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
	if input.accel and input.brake and cur_boost_type == BoostType.NONE:
		speed_delta = get_brake_speed()
	elif input.accel or cur_boost_type != BoostType.NONE:
		speed_delta = get_accel_speed()
	elif input.brake:
		speed_delta = get_reverse_speed()
	else:
		speed_delta = get_friction_speed()
	
	var new_speed := clampf(cur_speed + speed_delta * delta, -max_speed, max_speed)
	cur_speed = move_toward(cur_speed, new_speed, delta * grip)

	velocity.prop_vel = transform.basis.x.normalized() * cur_speed

func rotate_accel_along_floor() -> void:	
	# Rotate the propulsion direction
	if grounded and !prev_grounded:
		# We were in the air and have now landed
		along_ground_multi = 1.0
	
	var angle_z := velocity.prop_vel.normalized().angle_to(floor_normal)
	var angle_to_ground := 90 - rad_to_deg(angle_z)
	
	var new_prop_vel := velocity.prop_vel.rotated(transform.basis.z, -deg_to_rad(angle_to_ground))
	velocity.prop_vel = velocity.prop_vel.normalized().slerp(new_prop_vel.normalized(), along_ground_multi) * velocity.prop_vel.length()

	along_ground_multi -= along_ground_dec * delta
	along_ground_multi = clamp(along_ground_multi, 0.0, 1.0)
	return

func outside_drift_force() -> void:
	return

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
	
	# Rotate the vehicle to match the ground.
	var multi := 0.1

	if below_normals:
		multi = float(len(below_normals)) / len(floor_check_grid)

	var prev_y := rotation.y
	rotation = rotation.rotated(transform.basis.z.normalized(), transform.basis.y.signed_angle_to(floor_normal, transform.basis.z) * ground_rot_multi * multi * delta)
	rotation = rotation.rotated(transform.basis.x.normalized(), transform.basis.y.signed_angle_to(floor_normal, transform.basis.x) * ground_rot_multi * multi * delta)
	rotation.y = prev_y

func rotate_to_gravity() -> void:
	if grounded:
		return
	
	var prev_y := rotation.y
	rotation = rotation.rotated(transform.basis.z.normalized(), transform.basis.y.signed_angle_to(-gravity, transform.basis.z) * air_rot_multi * delta)
	rotation = rotation.rotated(transform.basis.x.normalized(), transform.basis.y.signed_angle_to(-gravity, transform.basis.x) * air_rot_multi * delta)
	rotation.y = prev_y


func _on_boost_timer_timeout() -> void:
	cur_boost_type = BoostType.NONE
