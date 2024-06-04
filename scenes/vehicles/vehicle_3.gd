extends RigidBody3D

class_name Vehicle3

var check_idx = -1
var lap = 0

@export var max_speed: float = 20
@onready var cur_max_speed = max_speed
@onready var max_reverse_speed: float = max_speed * 0.5
@export var initial_accel: float = 10
@export var accel_exponent: float = 10
@export var spd_steering_decrease: float = 1.0

@onready var friction_initial_accel: float = initial_accel * 1.5
@onready var friction_exponent: float = accel_exponent

@onready var brake_initial_accel: float = initial_accel * 2.0
@onready var brake_exponent: float = accel_exponent

@onready var reverse_initial_accel: float = initial_accel * 0.5
@onready var reverse_exponent: float = accel_exponent

@export var max_turn_speed: float = 1.0
@export var drift_turn_multiplier: float = 1.75
#@onready var max_turn_speed_drift: float = max_turn_speed * drift_turn_multiplier
@export var drift_turn_min_multiplier: float = 0.5
@export var air_turn_multiplier: float = 0.15

var cur_turn_speed: float = 0
var turn_accel: float = 15

@export var trick_cooldown_time: float = 0.3
@export var trick_force: float = 1.0
var in_trick: bool = false
var trick_frames: int = 0
@onready var trick_boost_timer: Timer = $NormalBoostTimer

@onready var small_boost_max_speed: float = max_speed * 1.2
@onready var small_boost_initial_accel: float = initial_accel * 3
@onready var small_boost_exponent = accel_exponent

@onready var normal_boost_max_speed: float = max_speed * 1.4
@onready var normal_boost_initial_accel: float = initial_accel * 2
@onready var normal_boost_exponent = accel_exponent

@onready var big_boost_max_speed: float = max_speed * 1.6

@export var small_boost_duration: float = 0.6
@export var normal_boost_duration: float = 1.0
@export var big_boost_duration: float = 1.5

@onready var trick_boost_duration = normal_boost_duration

@export var vehicle_length_ahead: float = 1.0
@export var vehicle_length_behind: float = 1.0
@export var vehicle_width_bottom: float = 0.5

var stick_speed: float = 100
var stick_distance: float = 0.5
var stick_ray_count: int = 4
var air_frames: int = 0
var in_hop: bool = false
var in_hop_frames: int = 0
var in_drift: bool = false
var drift_dir: int = 0
@onready var min_hop_speed: float = max_speed * 0.5
var hop_force: float = 4.0
var can_hop: bool = true
#var global_hop: Vector3 = Vector3.ZERO

var drift_gauge: float = 0.0
@export var drift_gauge_max: float = 100.0
var drift_gauge_multi: float = 55.0

var still_turbo_max_speed: float = 1
var still_turbo_ready: bool = false

var cur_speed: float = 0

var grounded: bool = false

var gravity: Vector3 = Vector3.DOWN * 15
var terminal_velocity = 30

@export var grip_multiplier: float = 1.0
@export var default_grip: float = 100.0
var cur_grip: float = 100.0

var max_displacement_for_sleep = 0.003
var max_degrees_change_for_sleep = 0.01

var prev_vel: Vector3 = Vector3.ZERO

var prev_transform: Transform3D = Transform3D.IDENTITY

var sleep = false
var extra_fov: float = 0.0

var in_water = false
var water_bodies: Dictionary = {}

@export var wheel_max_up: float = 0.2
@export var wheel_max_down: float = 0.5
var wheel_markers: Array = []

func _ready():
	for wheel in $Wheels.get_children():
		var wheel_marker = Marker3D.new()
		wheel_marker.transform = wheel.transform
		wheel_markers.append(wheel_marker)

func _integrate_forces(physics_state: PhysicsDirectBodyState3D):
	var delta: float = physics_state.step
	var prev_vel: Vector3 = linear_velocity
	var prev_gravity_vel: Vector3 = prev_vel.project(gravity.normalized())
	#Debug.print(prev_gravity_vel)
	var prev_up_spd: float = prev_vel.project(transform.basis.y).y
	#Debug.print(str(prev_gravity_vel))

	var prev_origin = prev_transform.origin
	var prev_rotation = prev_transform.basis

	sleep = false
	if prev_origin.distance_to(transform.origin) < max_displacement_for_sleep and prev_transform.basis.x.angle_to(transform.basis.x) < max_degrees_change_for_sleep and prev_transform.basis.y.angle_to(transform.basis.y) < max_degrees_change_for_sleep and prev_transform.basis.z.angle_to(transform.basis.z) < max_degrees_change_for_sleep:
		transform = prev_transform
		sleep = true
	
	var is_accel = Input.is_action_pressed("accelerate")
	var is_brake = Input.is_action_pressed("brake")
	var steering: float = Input.get_axis("right", "left")
	var trick_input: bool = Input.is_action_pressed("trick")
	var contact_point_ahead: Vector3 = Vector3.INF
	var contact_point_behind: Vector3 = Vector3.INF
	cur_grip = default_grip
	grounded = false
	
	# Determine effective max speed
	cur_max_speed = max_speed
	cur_max_speed -= abs(cur_turn_speed) * spd_steering_decrease
	#Debug.print(cur_max_speed)
	
	if in_hop:
		in_hop_frames += 1
		if drift_dir == 0 and !is_equal_approx(steering, 0.0):
			drift_dir = -1
			if steering > 0:
				drift_dir = 1
	if in_drift and !Input.is_action_pressed("brake"):
		in_drift = false
	if not is_brake:
		can_hop = true
		drift_dir = 0
	
	#print("Contacts")
	for i in range(physics_state.get_contact_count()):
		var collider = physics_state.get_contact_collider_object(i) as Node
		if collider.is_in_group("floor"):
			grounded = true
			if in_hop and in_hop_frames > 2:
				# Switch from hop to drift
				if is_brake:
					# Block hopping
					can_hop = false
				in_hop = false
				in_hop_frames = 0
				if drift_dir == 0:
					in_drift = false
				else:
					in_drift = true
			
			if in_trick and trick_frames > 2:
				in_trick = false
				trick_frames = 0
				Debug.print(["Starting trick boost", trick_boost_timer])
				trick_boost_timer.start(trick_boost_duration)
		
		if collider.is_in_group("boost"):
			$NormalBoostTimer.start(normal_boost_duration)
		
		if collider.is_in_group("trick"):
			$TrickTimer.start(trick_cooldown_time)
			trick_boost_timer = $NormalBoostTimer
			trick_boost_duration = normal_boost_duration
		if collider.is_in_group("small_trick"):
			$TrickTimer.start(trick_cooldown_time)
			trick_boost_timer = $SmallBoostTimer
			trick_boost_duration = small_boost_duration

			# var global_contact_position: Vector3 = physics_state.get_contact_local_position(i)
			# # Transform to local space
			# var local_contact_position: Vector3 = global_contact_position - transform.origin
			# # Rotate the point to match the rotation of the vehicle
			# var rotated_contact_position: Vector3 = transform.basis.x.rotated(transform.basis.y, -rotation_degrees.y).rotated(transform.basis.z, -rotation_degrees.z).rotated(transform.basis.x, -rotation_degrees.x).normalized() * local_contact_position
			# #print("Rotated: ", rotated_contact_position)
			# var point_distance = rotated_contact_position.length()

			# if rotated_contact_position.x > 0:
			# 	if point_distance < contact_point_ahead.length():
			# 		contact_point_ahead = rotated_contact_position
			# else:
			# 	if point_distance < contact_point_behind.length():
			# 		contact_point_behind = rotated_contact_position

			#print(collider)
	#print("===")

	#print(contact_point_ahead, contact_point_behind)
	
	if not grounded and trick_input and not $TrickTimer.is_stopped():
		Debug.print("Trick input detected")
		in_trick = true
	
	var new_vel = Vector3.ZERO
	var ground_vel = get_grounded_vel(delta)
	if grounded:
		air_frames = 0
		new_vel = ground_vel
		#print("grounded ", new_vel)
	else:
		air_frames += 1
		new_vel = get_air_vel(delta)
		#print("airborne ", new_vel)
	
	if in_trick and not in_hop:
		trick_frames += 1
		new_vel += transform.basis.y * trick_force / (trick_frames+1)
	
	#print(speed_vec)
	
	var _gravity: Vector3 = gravity
	if (prev_gravity_vel + (_gravity*delta)).length() > terminal_velocity:
		_gravity = prev_gravity_vel.move_toward(gravity.normalized() * terminal_velocity, gravity.length() * delta) - prev_gravity_vel
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

	if in_water:
		cur_grip *= 0.5

	var target_vel: Vector3 = prev_vel.move_toward(new_vel, delta * cur_grip * grip_multiplier) + (_gravity * delta)
	linear_velocity = target_vel
	prev_vel = target_vel
	
	# Stick to ground.
	# Perform raycast in local -y direction
	if air_frames < 5 and !in_hop:
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
	var adjusted_steering = steering
	
	if in_drift:
		if drift_dir > 0:
			adjusted_steering = remap(adjusted_steering, -1, 1, drift_turn_min_multiplier, drift_turn_multiplier)
		else:
			adjusted_steering = remap(adjusted_steering, -1, 1, -drift_turn_multiplier, -drift_turn_min_multiplier)
		
		drift_gauge += remap(abs(adjusted_steering), drift_turn_min_multiplier, drift_turn_multiplier, 1, 2) * drift_gauge_multi * delta
		if drift_gauge > drift_gauge_max:
			drift_gauge = drift_gauge_max
	else:
		if drift_gauge >= drift_gauge_max:
			# Drift turbo
			$SmallBoostTimer.start(small_boost_duration)
		drift_gauge = 0.0
	#Debug.print(drift_gauge)
	
	var adjusted_max_turn_speed = 0.5/(2*max(0.0, cur_speed)+1) + max_turn_speed
	#Debug.print(adjusted_max_turn_speed)
	
	var turn_target = adjusted_steering * adjusted_max_turn_speed
	#if in_drift:
		#turn_target = steering * max_turn_speed_drift
	#if !grounded:
		#turn_target *= air_turn_multiplier
	var cur_turn_accel = turn_accel
	if !grounded:
		cur_turn_accel *= air_turn_multiplier * air_turn_multiplier*5
	cur_turn_speed = move_toward(cur_turn_speed, turn_target, cur_turn_accel * delta)
	rotation_degrees.y += cur_turn_speed
	if !grounded:
		linear_velocity = linear_velocity.rotated(transform.basis.y, deg_to_rad(cur_turn_speed))
	#Debug.print(in_drift)
	
	
	#TODO: Make this dependent on gravity vector
	if not sleep:
		rotation_degrees.x = move_toward(rotation_degrees.x, 0, 6 * delta)
	var floor_below = Util.raycast_for_group(self, transform.origin, transform.origin + transform.basis.y * -1, "floor", [self])
	if not grounded and (!in_hop or !floor_below):
		rotation_degrees.z = move_toward(rotation_degrees.z, 0, 30 * delta)


	# REFUSE TO GO UPSIDE DOWN (assuming we were at some point right side up)
	# TODO: Actually implement rolling over
	var angle_from_gravity = rad_to_deg(transform.basis.y.angle_to(-gravity))
	if angle_from_gravity >= 90:
		var prev_angle_from_gravity = rad_to_deg(prev_transform.basis.y.angle_to(-gravity))
		if prev_angle_from_gravity < 90:
			transform.basis = prev_transform.basis
		else:
			# PANIC
			rotation_degrees.z += 180
			Debug.print("ROTATION PANIC: Could not recover from upside down state")

	handle_particles()
	# handle_wheels()

	grounded = false
	prev_transform = transform


func get_grounded_vel(delta: float) -> Vector3:
	var is_accel = Input.is_action_pressed("accelerate")
	var is_brake = Input.is_action_pressed("brake")
	
	#print(is_accel, is_brake, steering)
	var hop_vel = Vector3.ZERO
	
	var should_hop = false
	if is_accel and is_brake:
		if cur_speed > min_hop_speed:
			if in_drift:
				cur_speed += get_accel_speed(delta)
			elif can_hop:
				# Perform hop for drift
				should_hop = true
			else:
				cur_speed += get_friction_speed(delta)
		else:
			in_drift = false
			# Decelerate to standstill
			cur_speed += get_brake_speed(delta)
			
			# Check if we can miniturbo
			if abs(cur_speed) <= still_turbo_max_speed:
				# Do miniturbo.
				if grounded and not still_turbo_ready and $StillTurboTimer.is_stopped():
					$StillTurboTimer.start()
					#Debug.print("Start building up miniturbo")
	else:
		if is_accel:
			if still_turbo_ready:
				still_turbo_ready = false
				# Perform miniturbo.
				#Debug.print("Performing miniturbo")
				$SmallBoostTimer.start(small_boost_duration)
				
			cur_speed += get_accel_speed(delta)
		elif is_brake:
			in_drift = false
			cur_speed += get_reverse_speed(delta)
		else:
			in_drift = false
			cur_speed += get_friction_speed(delta)
		
		if not $StillTurboTimer.is_stopped():
			$StillTurboTimer.stop()
			#Debug.print("Stopped building up miniturbo")
		if still_turbo_ready:
			still_turbo_ready = false
			#Debug.print("Cancelled miniturbo")
	
	# Apply boosts
	cur_speed += get_boost_speed(delta)
	
	#global_hop = Vector3.ZERO
	#if not grounded and in_trick:
		#should_hop = true
		#global_hop = transform.basis.y * hop_force / (in_hop_frames+1)
	
	if should_hop:
		in_hop = true
		hop_vel = transform.basis.y * hop_force / (in_hop_frames+1)

	print(cur_speed)
	
	var speed_vel = transform.basis.x.normalized() * cur_speed
	
	var vel = speed_vel + hop_vel;
	
	return vel


func get_air_vel(delta: float) -> Vector3:
	return linear_velocity


func get_accel_speed(delta: float) -> float:
	if cur_speed < 0:
		# Braking
		return brake_initial_accel * delta

	# Accelerating
	return Util.get_vehicle_accel(cur_max_speed, cur_speed, initial_accel, accel_exponent) * delta


func get_reverse_speed(delta: float) -> float:
	if cur_speed > 0:
		# Braking
		return -brake_initial_accel * delta
	
	if !grounded:
		return 0

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

	return Util.get_vehicle_accel(cur_max_speed, abs(abs(cur_speed) - cur_max_speed), friction_initial_accel, friction_exponent) * delta * mult


func get_boost_speed(delta: float) -> float:
	if not $NormalBoostTimer.is_stopped():
		# Normal boost is active
		return Util.get_vehicle_accel(normal_boost_max_speed, cur_speed, normal_boost_initial_accel, normal_boost_exponent) * delta

	if not $SmallBoostTimer.is_stopped():
		# Small boost is active
		return Util.get_vehicle_accel(small_boost_max_speed, cur_speed, small_boost_initial_accel, small_boost_exponent) * delta
	
	if cur_speed > cur_max_speed:
		var speed_range = big_boost_max_speed - cur_max_speed
		var ratio = big_boost_max_speed - cur_speed
		return -Util.get_vehicle_accel(speed_range, ratio, friction_initial_accel, friction_exponent) * delta
	return 0

func _on_still_turbo_timer_timeout():
	#Debug.print("Miniturbo ready")
	still_turbo_ready = true


func handle_particles():
	handle_drift_particles()


func handle_drift_particles():
	$DriftParticles/CenterCharging.visible = false
	$DriftParticles/CenterCharged.visible = false
	$DriftParticles/LeftCharging.visible = false
	$DriftParticles/LeftCharged.visible = false
	$DriftParticles/RightCharging.visible = false
	$DriftParticles/RightCharged.visible = false
	
	if in_drift:
		if drift_gauge >= drift_gauge_max:
			if drift_dir > 0:
				$DriftParticles/LeftCharged.visible = true
			else:
				$DriftParticles/RightCharged.visible = true
		else:
			if drift_dir > 0:
				$DriftParticles/LeftCharging.visible = true
			else:
				$DriftParticles/RightCharging.visible = true
	elif !$StillTurboTimer.is_stopped():
		$DriftParticles/CenterCharging.visible = true
	elif still_turbo_ready:
		$DriftParticles/CenterCharged.visible = true

# func _physics_process(delta):
# 	handle_wheels(delta)

# func handle_wheels(delta):
# 	for i in range(len($Wheels.get_children())):
# 		var wheel = $Wheels.get_child(i) as RigidBody3D
# 		var wheel_marker = wheel_markers[i]

# 		var wheel_radius = wheel.get_node("CollisionShape3D").shape.radius

# 		var ray_start = wheel_marker.transform.origin + wheel_marker.transform.basis.y * (wheel_max_up - wheel_radius)
# 		var ray_end = wheel_marker.transform.origin + -wheel_marker.transform.basis.y * (wheel_max_down + wheel_radius)
# 		var col_dict = Util.raycast_for_group(wheel_marker, ray_start, ray_end, "floor", [wheel])

# 		var distance = wheel_max_down

# 		if col_dict:
# 			distance = col_dict["distance"]
		
# 		wheel.transform = wheel_marker.transform.translated(wheel_marker.transform.basis.y * (distance - wheel_radius))


func _process(delta):
	# UI Stuff
	var spd = linear_velocity.length()
	UI.update_speed(spd)
	
	if cur_speed > max_speed:
		extra_fov = (cur_speed - max_speed) * 0.25
	else:
		extra_fov = 0.0
	
	Debug.print([lap, check_idx])


func water_entered(area):
	in_water = true
	water_bodies[area] = true


func water_exited(area):
	water_bodies.erase(area)
	if water_bodies.size() == 0:
		in_water = false
