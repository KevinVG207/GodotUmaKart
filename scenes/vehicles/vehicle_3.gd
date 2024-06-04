extends RigidBody3D

class_name Vehicle3

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

@onready var small_boost_max_speed: float = max_speed * 1.2
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
var in_hop: bool = false
var in_hop_frames: int = 0
var in_drift: bool = false
var drift_dir: int = 0
@onready var min_hop_speed: float = max_speed * 0.5
var hop_force: float = 4.0
var can_hop: bool = true

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
var cur_grip: float = 100.0

var prev_vel: Vector3 = Vector3.ZERO


func _ready():
	pass
	

func _integrate_forces(physics_state: PhysicsDirectBodyState3D):
	var delta: float = physics_state.step
	var prev_vel: Vector3 = linear_velocity
	var prev_gravity_vel: Vector3 = prev_vel.project(gravity.normalized())
	#Debug.print(prev_gravity_vel)
	var prev_up_spd: float = prev_vel.project(transform.basis.y).y
	#Debug.print(str(prev_gravity_vel))
	
	var is_accel = Input.is_action_pressed("accelerate")
	var is_brake = Input.is_action_pressed("brake")
	var steering: float = Input.get_axis("right", "left")
	
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

	grounded = false

	var contact_point_ahead: Vector3 = Vector3.INF
	var contact_point_behind: Vector3 = Vector3.INF
	
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
			$SmallBoostTimer.start(miniturbo_duration)
		drift_gauge = 0.0
	#Debug.print(drift_gauge)
	
	var adjusted_max_turn_speed = 0.5/(2*max(0.0, cur_speed)+1) + max_turn_speed
	#Debug.print(adjusted_max_turn_speed)
	
	var turn_target = adjusted_steering * adjusted_max_turn_speed
	#if in_drift:
		#turn_target = steering * max_turn_speed_drift
	if !grounded:
		turn_target *= air_turn_multiplier
	var cur_turn_accel = turn_accel
	if !grounded:
		cur_turn_accel *= air_turn_multiplier * air_turn_multiplier*5
	cur_turn_speed = move_toward(cur_turn_speed, turn_target, cur_turn_accel * delta)
	rotation_degrees.y += cur_turn_speed
	if !grounded:
		linear_velocity = linear_velocity.rotated(transform.basis.y, deg_to_rad(cur_turn_speed))
	#Debug.print(in_drift)
	
	
	#TODO: Change this. Use function to determine angular velocity to turn back to 0.
	#TODO: Rotate to match gravity!
	rotation_degrees.x = move_toward(rotation_degrees.x, 0, 2.0)
	var floor_below = Util.raycast_for_group(self, transform.origin, transform.origin + transform.basis.y * -1, "floor", [self])
	if not grounded and (!in_hop or !floor_below):
		rotation_degrees.z = move_toward(rotation_degrees.z, 0, 0.5)
		
	determine_drift_particles()
	
	grounded = false


func get_grounded_vel(delta: float) -> Vector3:
	var is_accel = Input.is_action_pressed("accelerate")
	var is_brake = Input.is_action_pressed("brake")
	
	#print(is_accel, is_brake, steering)
	var hop_vel = Vector3.ZERO
	
	if is_accel and is_brake:
		if cur_speed > min_hop_speed:
			if in_drift:
				cur_speed += get_accel_speed(delta)
			elif can_hop:
				# Perform hop for drift
				in_hop = true
				hop_vel = transform.basis.y * hop_force / (in_hop_frames+1)
			else:
				cur_speed += get_friction_speed(delta)
		else:
			in_drift = false
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
			in_drift = false
			cur_speed += get_reverse_speed(delta)
		else:
			in_drift = false
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
	if not $SmallBoostTimer.is_stopped():
		# Small boost is active
		return Util.get_vehicle_accel(small_boost_max_speed, cur_speed, small_boost_initial_accel, small_boost_exponent) * delta
	
	if cur_speed > cur_max_speed:
		var speed_range = big_boost_max_speed - cur_max_speed
		var ratio = big_boost_max_speed - cur_speed
		return -Util.get_vehicle_accel(speed_range, ratio, friction_initial_accel, friction_exponent) * delta
	return 0

func _on_still_turbo_timer_timeout():
	Debug.print("Miniturbo ready")
	still_turbo_ready = true

func _process(delta):
	# UI Stuff
	var spd = linear_velocity.length()
	UI.update_speed(spd)

func determine_drift_particles():
	$DriftChargingParticles.emitting = false
	$DriftChargedParticles.emitting = false
	
	if in_drift:
		if drift_gauge >= drift_gauge_max:
			$DriftChargedParticles.emitting = true
		else:
			$DriftChargingParticles.emitting = true
	elif !$StillTurboTimer.is_stopped():
		$DriftChargingParticles.emitting = true
	elif still_turbo_ready:
		$DriftChargedParticles.emitting = true
