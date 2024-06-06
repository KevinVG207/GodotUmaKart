extends RigidBody3D

class_name Vehicle3

#var peer_id: int
#var initial_transform: Transform3D

var mutex: Mutex

@export var is_player: bool = false
@export var is_cpu: bool = true
var check_idx: int = -1
var check_key_idx: int = 0
var check_progress: float = 0.0
var lap: int = 0
var rank: int = 0

var input_accel: bool = false
var input_brake: bool = false
var input_steer: float = 0
var input_trick: bool = false
var input_mirror: bool = false

@export var max_speed: float = 20
@onready var cur_max_speed = 20
@onready var max_reverse_speed: float = max_speed * 0.5
@export var initial_accel: float = 10
@export var accel_exponent: float = 10
@export var spd_steering_decrease: float = 1.0
@export var weight_multi: float = 1.0
var push_force: float = 120
var max_push_force: float = 2.75

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

@export var cur_turn_speed: float = 0
var turn_accel: float = 15

var trick_cooldown_time: float = 0.3
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
@export var air_frames: int = 0
@export var in_hop: bool = false
@export var in_hop_frames: int = 0
@export var in_drift: bool = false
@export var drift_dir: int = 0
@onready var min_hop_speed: float = max_speed * 0.5
var hop_force: float = 4.0
@export var can_hop: bool = true
#var global_hop: Vector3 = Vector3.ZERO

@export var drift_gauge: float = 0.0
@export var drift_gauge_max: float = 100.0
var drift_gauge_multi: float = 55.0

var still_turbo_max_speed: float = 1
var still_turbo_ready: bool = false

@export var cur_speed: float = 0

@export var grounded: bool = false

@export var gravity: Vector3 = Vector3.DOWN * 15
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

var bounce_force: float = 10
@export var bounce_frames: int = 0
@export var prev_frame_pre_sim_vel: Vector3 = Vector3.ZERO
@onready var min_bounce_speed: float = max_speed * 0.4

@export var wheel_max_up: float = 0.2
@export var wheel_max_down: float = 0.5
var wheel_markers: Array = []

var colliding_vehicles: Dictionary = {}

#func _enter_tree():
	#set_multiplayer_authority(peer_id)
	#if is_multiplayer_authority():
		#is_player = true
		#is_cpu = false
	

func _ready():
	mutex = Mutex.new()
	pass
	#Network.should_setup = true
	#transform = initial_transform
	#for wheel in $Wheels.get_children():
		#var wheel_marker = Marker3D.new()
		#wheel_marker.transform = wheel.transform
		#wheel_markers.append(wheel_marker)

func handle_input():
	if is_player and get_window().has_focus():
		input_accel = Input.is_action_pressed("accelerate")
		input_brake = Input.is_action_pressed("brake")
		input_steer = Input.get_axis("right", "left")
		input_trick = Input.is_action_pressed("trick")
		input_mirror = Input.is_action_pressed("mirror")

func _integrate_forces(physics_state: PhysicsDirectBodyState3D):
	handle_input()
	if !is_player:
		set_collision_layer_value(1, false)
		set_collision_layer_value(2, true)
	else:
		set_collision_layer_value(1, true)
		set_collision_layer_value(2, false)
		
	var delta: float = physics_state.step
	var prev_vel: Vector3 = linear_velocity
	var prev_gravity_vel: Vector3 = prev_vel.project(gravity.normalized())


	var prev_origin = prev_transform.origin
	var prev_rotation = prev_transform.basis

	sleep = false
	if prev_origin.distance_to(transform.origin) < max_displacement_for_sleep and prev_transform.basis.x.angle_to(transform.basis.x) < max_degrees_change_for_sleep and prev_transform.basis.y.angle_to(transform.basis.y) < max_degrees_change_for_sleep and prev_transform.basis.z.angle_to(transform.basis.z) < max_degrees_change_for_sleep:
		transform = prev_transform
		sleep = true
	
	var is_accel = input_accel
	var is_brake = input_brake
	var steering: float = clamp(input_steer, -1.0, 1.0)
	var trick_input: bool = input_trick
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
	if in_drift and !input_brake:
		in_drift = false
	if not is_brake:
		can_hop = true
		drift_dir = 0
	
	var wall_contacts: Array = []
	
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
		
		if collider.is_in_group("wall"):
			wall_contacts.append({
				"normal": physics_state.get_contact_local_normal(i),
				"position": physics_state.get_contact_local_position(i),
				"object": collider
			})


	# Handle walls
	if bounce_frames > 0:
		bounce_frames -= 1
	if wall_contacts.size() > 0:
		var avg_normal: Vector3 = Vector3.ZERO
		var avg_position: Vector3 = Vector3.ZERO
		# print("===")
		for wall in wall_contacts:
			# print(wall["normal"])
			avg_normal += wall["normal"]
			avg_position += wall["position"]
		avg_normal /= wall_contacts.size()
		avg_position /= wall_contacts.size()
		# var avg_normal = wall_contacts[-1]["normal"]

		var bounce_ratio = 0.2
		for wall in wall_contacts:
			var col_obj = wall["object"]
			if col_obj.get("physics_material_override") and col_obj.physics_material_override.get("bounce"):
				var cur_bounce_ratio = col_obj.physics_material_override.bounce
				if cur_bounce_ratio > bounce_ratio:
					bounce_ratio = cur_bounce_ratio
		
		# If we are already moving away from the wall, don't bounce
		var dp = avg_normal.normalized().dot(prev_frame_pre_sim_vel.normalized())
		if dp < 0:
			# Get the component of the linear velocity that is perpendicular to the wall
			var perp_vel = prev_frame_pre_sim_vel.project(avg_normal).length()
			#Debug.print(perp_vel)
			var new_max_speed = (1 - abs(dp)) * cur_max_speed
			if perp_vel > min_bounce_speed:
				linear_velocity = prev_frame_pre_sim_vel.bounce(avg_normal.normalized()) * bounce_ratio
				if grounded:
					linear_velocity += -gravity.normalized() * bounce_force * bounce_ratio
				grounded = false
				prev_vel = linear_velocity
				bounce_frames = 3
				wall_contacts = []
			cur_speed = clamp(cur_speed, -new_max_speed, new_max_speed)

	
	if not grounded and trick_input and not $TrickTimer.is_stopped():
		Debug.print("Trick input detected")
		in_trick = true
	
	var new_vel = Vector3.ZERO
	var ground_vel = get_grounded_vel(delta)
	if grounded and bounce_frames == 0:
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

	angular_velocity = Vector3.ZERO

	if in_water:
		cur_grip *= 0.5

	var target_vel: Vector3 = prev_vel.move_toward(new_vel, delta * cur_grip * grip_multiplier) + (_gravity * delta)
	linear_velocity = target_vel
	prev_vel = target_vel
	
	# Stick to ground.
	# Perform raycast in local -y direction
	if air_frames < 5 and !in_hop and bounce_frames == 0:
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

	handle_vehicle_collisions(delta)

	handle_particles()
	# handle_wheels()

	grounded = false
	prev_transform = transform
	prev_frame_pre_sim_vel = linear_velocity


func get_grounded_vel(delta: float) -> Vector3:
	var is_accel = input_accel
	var is_brake = input_brake
	
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
		elif is_brake and grounded:
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
	
	if should_hop:
		in_hop = true
		hop_vel = transform.basis.y * hop_force / (in_hop_frames+1)
	
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

func handle_vehicle_collisions(delta: float):
	if colliding_vehicles.size() > 0:
		for col_vehicle: Vehicle3 in colliding_vehicles.keys():
			var push_dir: Vector3 = -(col_vehicle.global_position - global_position).normalized()
			
			var dir_multi: float = 1.0
			var dp: float = linear_velocity.normalized().dot(col_vehicle.linear_velocity.normalized())
			dp -= 2
			dp = -dp / 3
			
			var new_push_force: Vector3 = push_dir * push_force * col_vehicle.weight_multi * (1/weight_multi) * dp * ((linear_velocity.length() + col_vehicle.linear_velocity.length()) / 2) * delta

			var push_force_along_gravity = new_push_force.project(transform.basis.y.normalized())
			new_push_force -= push_force_along_gravity

			if new_push_force.length() > max_push_force:
				new_push_force = new_push_force.normalized() * max_push_force
			#Debug.print(["Push force", push_force.length()])
			linear_velocity += new_push_force

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
	#if is_multiplayer_authority() and not is_cpu:
		#is_player = true
	
	if is_player:
		var spd = linear_velocity.length()
		UI.update_speed(spd)
		
		if cur_speed > max_speed:
			extra_fov = (cur_speed - max_speed) * 0.25
		else:
			extra_fov = 0.0
	
		#print(cur_speed)
		#Debug.print([lap, check_idx, "%.2f" % check_progress, check_key_idx])


func water_entered(area):
	in_water = true
	water_bodies[area] = true


func water_exited(area):
	water_bodies.erase(area)
	if water_bodies.size() == 0:
		in_water = false


func _on_player_collision_area_entered(area: Area3D):
	var area_parent = area.get_parent()
	if not area_parent is Vehicle3:
		return
	#Debug.print([self, "collided with", area_parent])
	colliding_vehicles[area_parent] = true


func _on_player_collision_area_exited(area):
	var area_parent = area.get_parent()
	if not area_parent is Vehicle3:
		return
	#Debug.print([self, "uncollided with", area_parent])
	colliding_vehicles.erase(area_parent)
	
func upload_data():
	mutex.lock()
	#Network.vehicle_data
	var state: Dictionary = get_state()
	for key in state.keys():
		Network.vehicle_data[key] = state[key]
	mutex.unlock()

func get_state() -> Dictionary:
	return {
		"pos": Util.to_array(global_position),
		"rot": Util.to_array(rotation)
	}

func apply_state(state: Dictionary):
	global_position = Util.to_vector3(state["pos"])
	rotation = Util.to_vector3(state["rot"])
