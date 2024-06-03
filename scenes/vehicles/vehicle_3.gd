extends RigidBody3D

class_name Vehicle3

@export var max_speed: float
@onready var max_reverse_speed: float = max_speed * 0.5
@export var initial_accel: float
@export var accel_exponent: float

@onready var friction_initial_accel: float = initial_accel * 1.5
@onready var friction_exponent: float = accel_exponent

@onready var brake_initial_accel: float = initial_accel * 2.0
@onready var brake_exponent: float = accel_exponent

@onready var reverse_initial_accel: float = initial_accel * 0.5
@onready var reverse_exponent: float = accel_exponent

@export var max_turn_speed: float
var cur_turn_speed: float = 0
var turn_accel: float = 10

@export var small_boost_max_speed: float
@onready var small_boost_initial_accel: float = initial_accel * 3
@onready var small_boost_exponent = accel_exponent

@export var big_boost_max_speed: float

@export var miniturbo_duration: float

@export var vehicle_length_ahead: float = 1.0
@export var vehicle_length_behind: float = 1.0
@export var vehicle_width_bottom: float = 0.5

var stick_speed: float = 75
var stick_distance: float = 0.5
var stick_ray_count: int = 4
var air_frames: int = 0

var still_turbo_max_speed: float = 1
var still_turbo_ready: bool = false

var cur_speed: float = 0

var grounded: bool = false

var gravity: Vector3 = Vector3.DOWN * 10
var terminal_velocity = 20

@export var grip_multiplier: float = 1.0
var cur_grip: float = 100.0

var prev_vel: Vector3 = Vector3.ZERO


func _ready():
	pass


func _integrate_forces(physics_state: PhysicsDirectBodyState3D):
	var delta: float = physics_state.step
	var prev_vel: Vector3 = linear_velocity
	var prev_gravity_vel: Vector3 = prev_vel.project(gravity.normalized())
	var prev_up_spd: float = prev_vel.project(transform.basis.y).y
	#Debug.print(str(prev_gravity_vel))

	grounded = false

	var contact_point_ahead: Vector3 = Vector3.INF
	var contact_point_behind: Vector3 = Vector3.INF
	
	#print("Contacts")
	for i in range(physics_state.get_contact_count()):
		var collider = physics_state.get_contact_collider_object(i) as Node
		if collider.is_in_group("floor"):
			grounded = true
			var global_contact_position: Vector3 = physics_state.get_contact_local_position(i)
			# Transform to local space
			var local_contact_position: Vector3 = global_contact_position - transform.origin
			# Rotate the point to match the rotation of the vehicle
			var rotated_contact_position: Vector3 = transform.basis.x.rotated(transform.basis.y, -rotation_degrees.y).rotated(transform.basis.z, -rotation_degrees.z).rotated(transform.basis.x, -rotation_degrees.x).normalized() * local_contact_position
			#print("Rotated: ", rotated_contact_position)
			var point_distance = rotated_contact_position.length()

			if rotated_contact_position.x > 0:
				if point_distance < contact_point_ahead.length():
					contact_point_ahead = rotated_contact_position
			else:
				if point_distance < contact_point_behind.length():
					contact_point_behind = rotated_contact_position

			#print(collider)
	#print("===")

	#print(contact_point_ahead, contact_point_behind)
	
	var new_vel = Vector3.ZERO
	if grounded:
		air_frames = 0
		new_vel = get_grounded_vel(delta)
		#print("grounded ", new_vel)
	else:
		air_frames += 1
		new_vel = get_air_vel(delta)
		#print("airborne ", new_vel)
	
	#print(speed_vec)
	
	var _gravity: Vector3 = gravity
	#if (prev_gravity_vel.y < -terminal_velocity):
		#_gravity = Vector3.ZERO
	if grounded:
		_gravity *= 2
		#angular_velocity *= 0.5
		#if contact_point_ahead == Vector3.INF:
			#Debug.print("A")
			## Front of the capsule is in the air.
			## Try to stick to the ground.
			#var col_point = {}
			#for i in range(1, stick_ray_count + 1):
				#var hor_dist = vehicle_length_ahead / stick_ray_count * i
				#var ray_origin = transform.origin + (transform.basis.y * -vehicle_width_bottom) + (transform.basis.x * (hor_dist))
				#var ray_end = ray_origin + (transform.basis.y * -stick_distance)
				#var col_dict = Util.raycast_for_group(self, ray_origin, ray_end, "floor", [])
				##Debug.print(col_dict)
				#if not col_dict:
					#continue
				#col_dict["hor_dist"] = hor_dist
				#if not col_point:
					#col_point = col_dict
				#if col_dict["distance"] < col_point["distance"]:
					#col_point = col_dict
			#Debug.print("B")
			#if col_point:
				#var local_contact = to_local(contact_point_behind)
				#var local_col = to_local(col_point["position"])
#
				#var opposite = local_col.y - local_contact.y
				#var adjacent = local_col.x - local_contact.x
#
				#var angle = -atan(opposite / adjacent)
#
				#Debug.print([opposite, adjacent, angle])


	#if not grounded:
		#angular_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	var target_vel: Vector3 = prev_vel.move_toward(new_vel, delta * cur_grip * grip_multiplier) + (_gravity * delta)
	linear_velocity = target_vel
	prev_vel = target_vel
	
	# Stick to ground.
	# Perform raycast in local -y direction
	if air_frames < 5:
		var space_state = get_world_3d().direct_space_state
		var ray_origin = transform.origin + transform.basis.y * -0.5
		var ray_end = ray_origin + transform.basis.y * -0.9
		var ray_result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 0xFFFFFFFF, [self]))

		if ray_result:
			# var distance = ray_result.position.distance_to(ray_origin)
			# Apply stick_speed to stick to ground
			linear_velocity += -transform.basis.y.project(gravity.normalized()) * stick_speed * delta
			#Debug.print(linear_velocity.y)

	# Turning
	var steering: float = Input.get_axis("right", "left")
	var turn_target: float = steering * max_turn_speed
	cur_turn_speed = move_toward(cur_turn_speed, turn_target, turn_accel * delta)
	rotation_degrees.y += cur_turn_speed
	
	
	#TODO: Change this. Use function to determine angular velocity to turn back to 0.
	#TODO: Rotate to match gravity!
	rotation_degrees.x = move_toward(rotation_degrees.x, 0, 2.0)
	if not grounded:
		rotation_degrees.z = move_toward(rotation_degrees.z, 0, 0.5)
	
	grounded = false


func get_grounded_vel(delta: float) -> Vector3:
	var is_accel = Input.is_action_pressed("accelerate")
	var is_brake = Input.is_action_pressed("brake")
	
	#print(is_accel, is_brake, steering)
	
	if is_accel and is_brake:
		# TODO: Check for drift
		# Decelerate to standstill
		cur_speed += get_brake_speed(delta)
		
		# Check if we can miniturbo
		if abs(cur_speed) <= still_turbo_max_speed:
			# Do miniturbo.
			if not still_turbo_ready and $StillTurboTimer.is_stopped():
				$StillTurboTimer.start()
				Debug.print("Start building up miniturbo")
	else:
		if is_accel:
			if still_turbo_ready:
				still_turbo_ready = false
				# Perform miniturbo.
				Debug.print("Performing miniturbo")
				$SmallBoostTimer.start(miniturbo_duration)
				
			cur_speed += get_accel_speed(delta)
		elif is_brake:
			cur_speed += get_reverse_speed(delta)
		else:
			cur_speed += get_friction_speed(delta)
		
		if not $StillTurboTimer.is_stopped():
			$StillTurboTimer.stop()
			Debug.print("Stopped building up miniturbo")
		if still_turbo_ready:
			still_turbo_ready = false
			Debug.print("Cancelled miniturbo")
	
	# Apply boosts
	cur_speed += get_boost_speed(delta)

	print(cur_speed)
	
	# TODO: Delet this
	
	var vel = transform.basis.x.normalized() * cur_speed;
	
	return vel


func get_air_vel(delta: float) -> Vector3:
	return linear_velocity


func get_accel_speed(delta: float) -> float:
	if cur_speed < 0:
		# Braking
		return brake_initial_accel * delta

	# Accelerating
	return Util.get_vehicle_accel(max_speed, cur_speed, initial_accel, accel_exponent) * delta


func get_reverse_speed(delta: float) -> float:
	if cur_speed > 0:
		# Braking
		return -brake_initial_accel * delta

	# Reversing
	return -Util.get_vehicle_accel(max_reverse_speed, -cur_speed, reverse_initial_accel, reverse_exponent) * delta


func get_brake_speed(delta: float) -> float:
	var mult = -1.0

	if cur_speed < 0:
		mult = 1.0

	return Util.get_vehicle_accel(max_reverse_speed, abs(abs(cur_speed) - max_reverse_speed), brake_initial_accel, brake_exponent) * delta * mult


func get_friction_speed(delta: float) -> float:
	var mult = -1.0

	if cur_speed < 0:
		mult = 1.0

	return Util.get_vehicle_accel(max_speed, abs(abs(cur_speed) - max_speed), friction_initial_accel, friction_exponent) * delta * mult


func get_boost_speed(delta: float) -> float:
	if not $SmallBoostTimer.is_stopped():
		# Small boost is active
		return Util.get_vehicle_accel(small_boost_max_speed, cur_speed, small_boost_initial_accel, small_boost_exponent) * delta
	
	if cur_speed > max_speed:
		var speed_range = big_boost_max_speed - max_speed
		var ratio = big_boost_max_speed - cur_speed
		return -Util.get_vehicle_accel(speed_range, ratio, friction_initial_accel, friction_exponent) * delta
	return 0

func _on_still_turbo_timer_timeout():
	Debug.print("Miniturbo ready")
	still_turbo_ready = true

