extends RigidBody3D

class_name Vehicle4

var tick: int = -1
var delta: float = 1.0 / Engine.physics_ticks_per_second
var visual_delta := delta * 3.0

var physics_state: PhysicsDirectBodyState3D

var gravity := Vector3.DOWN * 20
@export var terminal_velocity: float = 3000

var prev_input := VehicleInput.new()
var input := VehicleInput.new()

var is_player := true
var is_cpu := false

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

var prev_contacts := {}
var contacts := {}
var ground_contacts := []
var prev_grounded := false
var grounded := false

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

var cur_boost_type: BoostType
@onready var boost_timer: Timer = %BoostTimer
enum BoostType {
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


var visual_event_queue := []

func _ready() -> void:
	print(ContactType.keys())

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

	if tick % 3 == 0:
		visual_tick()
		visual_delta = 0.0

	respawn_if_too_low()

	detect_collisions()

	handle_item()

	handle_steer()

	apply_velocities()

	Debug.print(velocity.total())
	return

func respawn_if_too_low() -> void:
	if global_position.y < -100:
		respawn()

func respawn() -> void:
	return

func set_inputs() -> void:
	prev_input = input

	if is_cpu:
		%CPU.set_inputs()
		return
	
	# TODO: Set inputs
	return


func detect_collisions() -> void:
	set_col_layer()

	handle_vehicle_collisions()

	build_contacts()

	determine_grounded()
	determine_max_speed_and_accel()

	determine_floor_normal()
	return

func determine_grounded() -> void:
	prev_grounded = grounded
	grounded = !ground_contacts.is_empty()
	return

func determine_max_speed_and_accel() -> void:
	return

func determine_floor_normal() -> void:
	return


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
								contact.speed_multi *= 1.4
							"STRONG":
								contact.speed_multi *= 0.6
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

func apply_boost(boost_type: BoostType):
	if boost_type <= cur_boost_type:
		return
	cur_boost_type = boost_type
	boost_timer.start(boosts[boost_type].length)

func handle_item() -> void:
	return

func handle_steer() -> void:
	angular_velocity = Vector3.ZERO
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

	# TODO: Apply velocity
	linear_velocity = velocity.total()
	return

func collide_vehicles() -> void:
	return

func collide_walls() -> void:
	return

func handle_hop() -> void:
	return

func stick_to_ground() -> void:
	return

func apply_gravity() -> void:
	var grav_component := velocity.grav_component(gravity)
	if grounded and grav_component.normalized().dot(gravity.normalized()) > 0:
		velocity.rest_vel -= grav_component
		velocity.rest_vel += gravity / 4

	velocity.rest_vel += gravity * delta

	grav_component = velocity.grav_component(gravity)
	if grav_component.length() >= terminal_velocity:
		velocity.rest_vel -= grav_component
		velocity.rest_vel += gravity.normalized() * terminal_velocity
