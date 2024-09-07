extends RigidBody3D

class_name Vehicle3

#var peer_id: int
#var initial_transform: Transform3D

var update_idx: int = 0
@onready var vani: VehicleAnimationTree = $VehicleAnimationTree
@onready var cani: AnimationPlayer # TODO: Character animation player

var frame: int = 0
var started: bool = false
var is_player: bool = false
var is_cpu: bool = true
var is_network: bool = false
var is_replay: bool = false
var user_id: String = ""
var check_idx: int = -1
var check_key_idx: int = 0
var check_progress: float = 0.0
var lap: int = 0
var rank: int = 999999
var finished: bool = false
var finish_time: float = 0
var username: String = "Player"
var world: RaceBase
var prev_state: Dictionary = {}
var reversing := false
var steering := 0.0

var cpu_target: EnemyPath = null
var cpu_target_offset: Vector3 = get_random_target_offset()
var cur_progress: float = -100000

var item: ItemBase = null
var can_use_item: bool = false
var moved_to_next: bool = false
var catch_up: bool = false

var input_accel: bool = false
var input_brake: bool = false
var input_steer: float = 0
var input_trick: bool = false
var input_mirror: bool = false
var input_item: bool = false
var input_item_just: bool = false
var input_updown: float = 0
@export var list_image: CompressedTexture2D
@export var list_order: int = 0
@export var icon: CompressedTexture2D
@export var max_speed: float = 25
@onready var cur_max_speed := max_speed
@onready var min_speed_for_detach := max_speed / 4
@export var reverse_multi: float = 0.5
@onready var max_reverse_speed: float = max_speed * reverse_multi
@export var initial_accel: float = 10
@export var accel_exponent: float = 10
@export var spd_steering_decrease: float = 0.025
@export var weight: float = 1.0
@export var weak_offroad_multiplier: float = 0.7
@export var offroad_multiplier: float = 0.5
var push_force: float = 12.0
# var max_push_force: float = 2.75
# var push_force_vert: float = 1.0
var offroad_ticks: int = 0
var offroad := false
var weak_offroad := false

var network_teleport_distance: float = 25.0

@export var outside_drift: bool = false
@export var outside_drift_force: float = 1000.0
var cur_outside_drift_force: float = 0.0
var outside_drift_force_reduction: float = 0.0

@onready var friction_initial_accel: float = initial_accel * 1.5
@onready var friction_exponent: float = accel_exponent

@onready var brake_initial_accel: float = initial_accel * 2.0
@onready var brake_exponent: float = accel_exponent

@onready var reverse_initial_accel: float = initial_accel * 0.5
@onready var reverse_exponent: float = accel_exponent

@export var max_turn_speed: float = 80.0
@export var drift_turn_multiplier: float = 1.2
#@onready var max_turn_speed_drift: float = max_turn_speed * drift_turn_multiplier
@export var drift_turn_min_multiplier: float = 0.5
@export var air_turn_multiplier: float = 0.5

@export var cur_turn_speed: float = 0
var turn_accel: float = 1800

var trick_cooldown_time: float = 0.4
@export var trick_force: float = 2.5
var in_trick: bool = false

@onready var small_boost_timer: Timer = $SmallBoostTimer
@onready var normal_boost_timer: Timer = $NormalBoostTimer
@onready var big_boost_timer: Timer = $BigBoostTimer
@onready var trick_boost_timer: Timer = normal_boost_timer

@onready var small_boost_max_speed: float = max_speed * 1.2
@onready var small_boost_initial_accel: float = initial_accel * 5
@onready var small_boost_exponent := accel_exponent

@onready var normal_boost_max_speed: float = max_speed * 1.4
@onready var normal_boost_initial_accel: float = initial_accel * 5
@onready var normal_boost_exponent := accel_exponent

@onready var big_boost_max_speed: float = max_speed * 1.6

@export var small_boost_duration: float = 0.6
@export var normal_boost_duration: float = 1.0
@export var big_boost_duration: float = 1.5

@onready var trick_boost_duration := normal_boost_duration

@export var vehicle_length_ahead: float = 1.0
@export var vehicle_length_behind: float = 1.0
@export var vehicle_height_below: float = 0.5

var stick_speed: float = 100
var stick_distance: float = 0.5
var stick_ray_count: int = 4
@export var air_frames: int = 0
@export var in_hop: bool = false
@export var in_hop_frames: int = 0
@export var in_drift: bool = false
@export var drift_dir: int = 0
@onready var min_hop_speed: float = max_speed * 0.5
var hop_force: float = 3.5
@export var can_hop: bool = true
#var global_hop: Vector3 = Vector3.ZERO
var is_stick: bool = false
var keep_grav: bool = false

@export var drift_gauge: float = 0.0
@export var drift_gauge_max: float = 100.0
var drift_gauge_multi: float = 55.0

var still_turbo_max_speed: float = 1
var still_turbo_ready: bool = false

@export var cur_speed: float = 0

var grounded: bool = false
var prev_grounded: bool = false

@export var gravity: Vector3 = Vector3.DOWN * 20
var terminal_velocity: float = 3000

# var grav_vel: Vector3 = Vector3.ZERO  # Velocity due to gravity
var prop_vel: Vector3 = Vector3.ZERO  # Velocity due to propulsion
var rest_vel: Vector3 = Vector3.ZERO  # Other velocity
var prev_prop_vel: Vector3 = Vector3.ZERO
var prev_rest_vel: Vector3 = Vector3.ZERO
var floor_normal := Vector3(0, 1, 0)
var floor_normals: Array = []
var wall_contacts: Array = []

@export var grip_multiplier: float = 1.0
@export var default_grip: float = 80.0
@export var air_decel: float = default_grip * 0.2
var ground_rot_multi: float = 6.0
#@export var default_grip_rest: float = 30.0
var test_force: float = 10.0
#var cur_grip: float = 100.0

var max_displacement_for_sleep := 0.003
var max_degrees_change_for_sleep := 0.5

var prev_vel: Vector3 = Vector3.ZERO

var prev_transform: Transform3D = Transform3D.IDENTITY
#@onready var prev_rotation: Vector3 = rotation

var sleep := false
var extra_fov: float = 0.0

var in_water := false
var water_bodies: Dictionary = {}

var bounce_force: float = 20.0
var in_bounce := false
var bounce_frames: int = 0
@export var prev_frame_pre_sim_vel: Vector3 = Vector3.ZERO
@onready var min_bounce_speed: float = max_speed * 0.4

#var colliding_vehicles: Dictionary = {}

var respawn_time: float = 3.5
var respawn_stage2_time: float = 1.0
var respawn_stage: int = 0
var respawn_position: Vector3 = Vector3.ZERO
var respawn_rotation: Vector3 = Vector3.ZERO

var targeted_by_dict: Dictionary = {}

var in_damage: int = DamageType.none
const DamageType = {
	none = 0,
	spin = 1,
	tumble = 2,
	explode = 3
}

var collided_with: Dictionary = {}

var floor_check_grid: Array = []
var floor_check_distance: float = 1.0

var wall_turn_multi: float = 1.0
var max_wall_turn_multi: float = 2.0

var along_ground_multi := 0.0
var along_ground_dec := 10.0
var min_angle_to_detach := 10.0

var replay_transparency := 0.75

#func _enter_tree():
	#set_multiplayer_authority(peer_id)
	#if is_multiplayer_authority():
		#is_player = true
		#is_cpu = false

func _ready() -> void:
	setup_floor_check_grid()
	setup_head()
	
	if is_replay:
		recursive_set_transparency($Visual)

	#Network.should_setup = true
	#transform = initial_transform

func setup_replay() -> void:
	is_player = false
	is_network = false
	is_cpu = false
	is_replay = true
	freeze_mode = FREEZE_MODE_STATIC
	freeze = true
	collision_layer = 0
	collision_mask = 0

func recursive_set_transparency(n: Node):
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

func make_player() -> void:
	is_cpu = false
	is_network = false
	is_player = true
	UI.race_ui.roulette_ended.connect(_on_roulette_stop)

func set_finished(_finish_time: float) -> void:
	finished = true
	finish_time = _finish_time
	if is_player:
		UI.race_ui.hide_roulette()
		UI.race_ui.finished()

func axis_lock() -> void:
	axis_lock_linear_x = true
	axis_lock_linear_z = true

func axis_unlock() -> void:
	started = true
	axis_lock_linear_x = false
	axis_lock_linear_z = false

func teleport(new_pos: Vector3, look_dir: Vector3, up_dir: Vector3) -> void:
	global_position = new_pos
	look_at_from_position(new_pos, new_pos + (look_dir.rotated(up_dir, deg_to_rad(-90))), up_dir, true)
	set_movement_zero()

func set_movement_zero() -> void:
	prev_transform = transform
	prev_frame_pre_sim_vel = Vector3.ZERO
	prev_vel = Vector3.ZERO
	prop_vel = Vector3.ZERO
	rest_vel = Vector3.ZERO
	prev_prop_vel = Vector3.ZERO
	cur_speed = 0
	cur_turn_speed = 0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	prop_vel = Vector3.ZERO
	rest_vel = Vector3.ZERO

func set_all_input_zero() -> void:
	input_accel = false
	input_brake = false
	input_steer = 0.0
	input_trick = false
	input_item = false
	input_item_just = false
	input_updown = 0.0

func get_random_target_offset() -> Vector3:
	return Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))

func handle_input() -> void:
	if is_player and get_window().has_focus():
		input_mirror = Input.is_action_pressed("mirror")

	if finished or (is_player and not get_window().has_focus()) or in_damage or is_cpu and !is_network:
		set_all_input_zero()
		return
	
	if !started:
		set_all_input_zero()
		return
	
	if is_player and get_window().has_focus():
		input_accel = Input.is_action_pressed("accelerate")
		input_brake = Input.is_action_pressed("brake") or Input.is_action_pressed("brake2")
		input_steer = Input.get_axis("right", "left")
		input_trick = Input.is_action_just_pressed("trick")
		input_item = Input.is_action_pressed("item")
		input_item_just = Input.is_action_just_pressed("item")
		input_updown = Input.get_axis("down", "up")

func cpu_control(delta: float) -> void:
	if !is_cpu or in_damage or !started:
		return
	
	if not cpu_target:
		return

	# CPU brain goes here
	if !is_network:
		set_all_input_zero()
	
	if !is_network and !$TrickTimer.is_stopped():
		if randf() < (0.25 / Engine.physics_ticks_per_second):
			input_trick = true
		if grounded and cur_speed > min_hop_speed and randf() < (1.0 / Engine.physics_ticks_per_second):
			input_brake = true
	
	var cpu_target_pos := cpu_target.global_position + (cpu_target_offset * cpu_target.dist / 3)
	if global_position.distance_to(cpu_target_pos) < cpu_target.dist or Util.dist_to_plane(cpu_target.normal, cpu_target.global_position, global_position) > 0:
		# Get next target
		cpu_target = world.pick_next_path_point(cpu_target)
		cpu_target_offset = get_random_target_offset()
		cpu_target_pos = cpu_target.global_position + (cpu_target_offset * cpu_target.dist / 3)
		moved_to_next = true
		# $FailsafeTimer.start()

	
	# Determine which side to steer
	var target_dir := (cpu_target_pos - global_position).normalized()
	var angle := transform.basis.z.angle_to(target_dir) - PI/2
	var max_angle := cpu_target.dist/2 / global_position.distance_to(cpu_target_pos)

	var is_behind := transform.basis.x.dot(target_dir) < 0

	if is_behind:
		if angle < 0:
			angle -= 10
		else:
			angle += 10

	if !is_network or prev_state and global_position.distance_to(Util.to_vector3(prev_state.pos)) > 3.0:
		input_accel = true

	if !is_network and abs(angle) > 0.5 and cur_speed > min_hop_speed and randf() < (2.0 / Engine.physics_ticks_per_second):
		input_brake = true
	
	if !is_network and (in_drift or in_hop or air_frames > Engine.physics_ticks_per_second/4.0) and (drift_gauge >= 75 or abs(angle) > 0.2):
		input_brake = true
	
	if abs(angle) > max_angle:
		# Should steer.
		if angle < 0:
			input_steer = -1.0
			if !is_network and in_drift and drift_dir > 0 and (drift_gauge <= 80 or drift_gauge == 100):
				input_brake = false
		else:
			input_steer = 1.0
			if !is_network and in_drift and drift_dir < 0 and (drift_gauge <= 80 or drift_gauge == 100):
				input_brake = false
	
	#if abs(angle) < max_angle:
		#if angle < 0:
			#input_steer = -1.0
		#else:
			#input_steer = 1.0
		#input_steer *= randf() * 0.2
	
	if is_network and prev_state:
		var network_pos: Vector3 = cpu_target.global_position
		var network_rot: Vector3 = Util.to_vector3(prev_state.rot)
		var move_multi := 0.0
		var rot_multi := 1.0
		
		#if !moved_to_next and (catch_up or global_position.distance_to(network_pos) > (network_teleport_distance / 3) * 2):
			##Debug.print("catch up!")
			#catch_up = true
			#move_multi = 2.0
		
		if !moved_to_next:
			#network_pos = cpu_target.global_position
			var dist: float = max(network_teleport_distance/2, global_position.distance_to(network_pos))
			move_multi = remap(dist, network_teleport_distance/2, network_teleport_distance, 0.0, 3.0)
		
		else:
			#catch_up = false
			move_multi = 0.0
		
		if prev_state.cur_speed < 5.0: # and global_position.distance_to(network_pos) < 3.0:
			network_pos = Util.to_vector3(prev_state.pos)
			move_multi = clamp(remap(prev_state.cur_speed, 0, 5.0, 2.0, 0.0), 0.0, 2.0)
			rot_multi = 3.0
			input_steer = 0.0
		
		#Debug.print(move_multi)
		var new_pos: Vector3 = global_position.lerp(network_pos, delta * move_multi)
		var new_movement: Vector3 = new_pos - global_position

		# Remove the component along the gravity vector
		var adjusted_movement: Vector3 = Plane(-gravity.normalized()).project(new_movement)
		var vertical_movement: Vector3 = new_movement - adjusted_movement

		global_position += adjusted_movement
		
		if vertical_movement.length() > network_teleport_distance / 2 and !moved_to_next:
			global_position = network_pos
		
		if global_position.distance_to(network_pos) < 5.0:
			catch_up = false
		
		var cur_quat := Quaternion.from_euler(rotation)
		var target_quat := Quaternion.from_euler(network_rot)
		rotation = cur_quat.slerp(target_quat, rot_multi * delta).get_euler()
	
	if !is_network:
		var item_rand := randi_range(0, 900) == 0
		# if item:
		# 	print(can_use_item, " ", item, " ", item_rand)
		if !finished and can_use_item and item and item_rand:
			input_item = true
			input_item_just = true
		
		var new_progress := world.get_vehicle_progress(self)
		if new_progress > cur_progress:
			cur_progress = new_progress
			$FailsafeTimer.stop()
		else:
			# No progress made in this frame.
			if $FailsafeTimer.is_stopped():
				start_failsafe_timer()

func _integrate_forces(physics_state: PhysicsDirectBodyState3D) -> void:
	frame += 1
	var delta: float = physics_state.step
	
	if finished and !is_network:
		is_cpu = true
	
	handle_input()
	cpu_control(delta)
	
	if !is_player:
		set_collision_layer_value(2, false)
		set_collision_layer_value(3, true)
	else:
		set_collision_layer_value(2, true)
		set_collision_layer_value(3, false)
		
	#var prev_vel: Vector3 = linear_velocity
	# var prev_gravity_vel: Vector3 = prev_vel.project(gravity.normalized())
	# var prev_grav_vel: Vector3 = grav_vel
	
	var tmp: Array = collided_with.keys()
	for vehicle: Vehicle3 in tmp:
		var timeout_frame: int = collided_with[vehicle]
		if frame >= timeout_frame:
			collided_with.erase(vehicle)


	var prev_origin := prev_transform.origin
	var _prev_basis := prev_transform.basis

	grip_multiplier = 1.0
	
	if in_water:
		grip_multiplier = 0.75

	sleep = false
	if !is_network and prev_prop_vel.length() < 0.01 and prev_origin.distance_to(transform.origin) < max_displacement_for_sleep and prev_transform.basis.x.angle_to(transform.basis.x) < max_degrees_change_for_sleep and prev_transform.basis.y.angle_to(transform.basis.y) < max_degrees_change_for_sleep and prev_transform.basis.z.angle_to(transform.basis.z) < max_degrees_change_for_sleep:
		transform = prev_transform
		sleep = true
	
	# is_accel = input_accel
	# is_brake = input_brake
	steering = clamp(input_steer, -1.0, 1.0)
	#cur_grip = default_grip
	grounded = false
	reversing = false
	
	# Determine effective max speed
	cur_max_speed = max_speed
	cur_max_speed -= abs(cur_turn_speed) * spd_steering_decrease
	
	if global_position.y < -100:
		respawn()
	
	#Debug.print(cur_max_speed)
	if in_bounce:
		bounce_frames += 1
	if in_hop:
		in_hop_frames += 1
		if drift_dir == 0 and !is_equal_approx(steering, 0.0):
			drift_dir = -1
			if steering > 0:
				drift_dir = 1
	if in_drift and !input_brake:
		in_drift = false
	if not input_brake:
		can_hop = true
		drift_dir = 0
	
	wall_contacts = []
	
	#print("Contacts")
	offroad = false
	weak_offroad = false
	floor_normals = []
	handle_contacts(physics_state)
	
	# Handle respawning
	handle_respawn()
	if respawn_stage == 2:
		return

	if offroad:
		cur_max_speed *= offroad_multiplier
	elif weak_offroad:
		cur_max_speed *= weak_offroad_multiplier
	
	if offroad_ticks and offroad_ticks < 10:
		cur_max_speed = 0.1
	
	if cur_max_speed < 0.1:
		cur_max_speed = 0.1
	
	max_reverse_speed = cur_max_speed * reverse_multi

	# Handle walls
	handle_walls()


	# Stick to ground.
	# Perform raycast in local -y direction
	is_stick = false
	keep_grav = false
	#if is_player:
		#print(in_hop, " ", grounded)
	detect_stick()

	
	if not grounded and input_trick and !$TrickTimer.is_stopped() and !in_trick:
		#if is_player:
			#Debug.print("Trick input detected")
		in_trick = true
		if not in_hop:
			rest_vel += transform.basis.y * trick_force

	if in_hop_frames == 1:
		grounded = false
	
	# var new_vel = Vector3.ZERO
	# var ground_vel = get_grounded_vel(delta)
	if grounded and !in_bounce:
		air_frames = 0
		# Apply friction to rest_vel along the ground
		#var rest_vel_rest = rest_vel.project(floor_normal)
		#var rest_vel_ground = rest_vel - rest_vel_rest

		#rest_vel_ground = rest_vel_ground.move_toward(Vector3.ZERO, default_grip_rest * delta)

		#rest_vel = rest_vel_ground
		
		# Remove gravity.
		var vel_grav := rest_vel.project(gravity.normalized())
		# print(vel_grav)
		rest_vel -= vel_grav
		
		rest_vel = rest_vel.move_toward(Vector3.ZERO, default_grip * delta)
		
		if keep_grav:
			#print("stick")
			rest_vel += vel_grav
		#if rest_vel.length() < max_displacement_for_sleep:
			#rest_vel = Vector3.ZERO

		prop_vel = get_grounded_vel(delta)
	else:
		air_frames += 1
		
		var grav_component := rest_vel.project(gravity.normalized())
		var other := rest_vel - grav_component
		other = other.move_toward(Vector3.ZERO, air_decel * delta)
		
		rest_vel = other + grav_component
		# new_vel = get_air_vel(delta)
		#print("airborne ", new_vel)
	
	#print(speed_vec)
	
	var _gravity: Vector3 = gravity
	# if (prev_gravity_vel + (_gravity*delta)).length() > terminal_velocity:
	# 	_gravity = prev_gravity_vel.move_toward(gravity.normalized() * terminal_velocity, gravity.length() * delta) - prev_gravity_vel
	if grounded and $TrickTimer.is_stopped():
		_gravity *= 1
	
	if in_bounce and bounce_frames < 9:
		_gravity = Vector3.ZERO
	if in_hop and in_hop_frames < 9:
		_gravity = Vector3.ZERO

	#if grounded:
		#new_grav *= 2
	rest_vel += _gravity * delta

	# var target_vel: Vector3 = prev_vel.move_toward(new_vel, delta * cur_grip * grip_multiplier) + (_gravity * delta)

	# print(prop_vel, " ", rest_vel, " ", linear_velocity)
	
	
	if is_stick:
		rest_vel += -transform.basis.y.project(gravity.normalized()) * stick_speed * delta

			#Debug.print(linear_velocity.y)

	# Turning
	var adjusted_steering := steering
	if respawn_stage:
		adjusted_steering = 0.0
	
	if in_drift:
		var outside_drift_multi: float = clamp((prop_vel + rest_vel).length() / cur_max_speed, 0, 1)
		if drift_dir > 0:
			adjusted_steering = remap(adjusted_steering, -1, 1, drift_turn_min_multiplier, drift_turn_multiplier)
			if outside_drift and grounded:
				rest_vel += transform.basis.z * cur_outside_drift_force * delta * outside_drift_multi
		else:
			adjusted_steering = remap(adjusted_steering, -1, 1, -drift_turn_multiplier, -drift_turn_min_multiplier)
			if outside_drift and grounded:
				rest_vel -= transform.basis.z * cur_outside_drift_force * delta * outside_drift_multi
		
		cur_outside_drift_force = move_toward(cur_outside_drift_force, 0, outside_drift_force_reduction * delta)
		
		drift_gauge += remap(abs(adjusted_steering), drift_turn_min_multiplier, drift_turn_multiplier, 1, 2) * drift_gauge_multi * delta
		if drift_gauge > drift_gauge_max:
			drift_gauge = drift_gauge_max
	else:
		if drift_gauge >= drift_gauge_max:
			# Drift turbo
			small_boost_timer.start(small_boost_duration)
		drift_gauge = 0.0
	#Debug.print(drift_gauge)
	
	var adjusted_max_turn_speed: float = 0.5/(2*max(0.001, cur_speed)+1) + max_turn_speed
	#Debug.print(adjusted_max_turn_speed)
	
	# Hacky attempt to fix being "stuck" to a wall
	if wall_contacts:
		wall_turn_multi += delta * 3
	else:
		wall_turn_multi = 1.0
	wall_turn_multi = clamp(wall_turn_multi, 1.0, max_wall_turn_multi)
	
	var turn_target := adjusted_steering * adjusted_max_turn_speed * wall_turn_multi

	var cur_turn_accel := turn_accel
	if reversing:
		turn_target *= -0.75
		cur_turn_accel *= 0.5
		cur_turn_speed = clamp(cur_turn_speed, -max_turn_speed*0.75, max_turn_speed*0.75)
	# if !grounded:
	# 	cur_turn_accel *= air_turn_multiplier * air_turn_multiplier*5

	if is_cpu:
		cur_turn_speed = move_toward(cur_turn_speed, turn_target, cur_turn_accel * delta * 2)
	else:
		cur_turn_speed = move_toward(cur_turn_speed, turn_target, cur_turn_accel * delta)
	
	var cur_multi := 1.0
	if !grounded:
		prop_vel = prop_vel.rotated(transform.basis.y, deg_to_rad(cur_turn_speed) * delta * air_turn_multiplier)
		rest_vel = rest_vel.rotated(transform.basis.y, deg_to_rad(cur_turn_speed) * delta * air_turn_multiplier)
		cur_multi *= air_turn_multiplier

	rotation_degrees.y += cur_turn_speed * delta * cur_multi
	# prop_vel = prop_vel.rotated(transform.basis.y, deg_to_rad(cur_turn_speed) * delta)
	# rest_vel = rest_vel.rotated(transform.basis.y, deg_to_rad(cur_turn_speed) * delta)
	# if !grounded:
	# 	linear_velocity = linear_velocity.rotated(transform.basis.y, deg_to_rad(cur_turn_speed) * delta)
	#Debug.print(in_drift)
	
	prop_vel = prev_prop_vel.move_toward(prop_vel, delta * default_grip * grip_multiplier)
	
	idle_rotate(delta)

	# REFUSE TO GO UPSIDE DOWN (assuming we were at some point right side up)
	# TODO: Actually implement rolling over
	var angle_from_gravity := rad_to_deg(transform.basis.y.angle_to(-gravity))
	if angle_from_gravity >= 90:
		var prev_angle_from_gravity := rad_to_deg(prev_transform.basis.y.angle_to(-gravity))
		if prev_angle_from_gravity < 90:
			transform.basis = prev_transform.basis
		else:
			# PANIC
			rotation_degrees.z += 180
			Debug.print("ROTATION PANIC: Could not recover from upside down state")

	handle_vehicle_collisions()

	# Limit rest_vel to terminal_velocity
	if rest_vel.length() > terminal_velocity:
		rest_vel = rest_vel.normalized() * terminal_velocity
	
	linear_velocity = prop_vel + rest_vel
	prev_vel = linear_velocity
	angular_velocity = Vector3.ZERO

	# if is_player:
	# 	print(grounded)

	# grounded = false
	
	prev_transform = transform
	prev_frame_pre_sim_vel = linear_velocity
	prev_prop_vel = prop_vel
	prev_rest_vel = rest_vel
	prev_grounded = grounded
	#print("Grounded: ", grounded)
	#prev_rotation = rotation


func raycast_floor_below() -> Array:
	var normals: Array = []
	
	for loc_start_pos: Vector3 in floor_check_grid:
		var start_pos := to_global(loc_start_pos)
		var end_pos := start_pos + (transform.basis.y.normalized() * -floor_check_distance)
		var result := Util.raycast_for_group(world.space_state, start_pos, end_pos, "floor", [self])
		if result:
			normals.append(result.normal)
	
	return normals

func idle_rotate(delta: float) -> void:
	#TODO: Make this dependent on gravity vector
	if not sleep:
		rotation_degrees.x = move_toward(rotation_degrees.x, 0, 6 * delta)
	#var floor_below = Util.raycast_for_group(world.space_state, transform.origin, transform.origin + transform.basis.y * -1, "floor", [self])
	var below_normals := raycast_floor_below()
	#if is_player:
		#print(len(floor_normals))
	if not grounded and (!in_hop or !below_normals):
		rotation_degrees.z = move_toward(rotation_degrees.z, 0, 30 * delta)

	if grounded:
		var avg_normal: Vector3 = floor_normal
		var multi: float = 1.0
		if below_normals:
			avg_normal = Util.sum(below_normals) / len(below_normals)
			multi = float(len(below_normals)) / len(floor_check_grid)
		else:
			# Floor is not under the player!!
			pass
		
		# Rotate the propulsion direction
		if not prev_grounded and grounded:
			# We were in the air and have now landed
			along_ground_multi = 1.0
		
		var angle_z := prop_vel.normalized().angle_to(avg_normal)
		var angle_to_ground := 90 - rad_to_deg(angle_z)
		
		var new_prop_vel := prop_vel.rotated(transform.basis.z, -deg_to_rad(angle_to_ground))
		prop_vel = prop_vel.normalized().slerp(new_prop_vel.normalized(), along_ground_multi) * prop_vel.length()
		along_ground_multi -= along_ground_dec * delta
		along_ground_multi = clamp(along_ground_multi, 0.0, 1.0)
		# print(angle_to_ground, " ", along_ground_multi)
		
		if cur_speed >= min_speed_for_detach and angle_to_ground >= min_angle_to_detach:
			#if is_player:
				#print("Steep snap!")
			bounce_frames += 1
			in_bounce = true
			# print("Detach")
			return
		
		# Rotate the vehicle to match the ground.
		var prev_y := rotation.y
		rotation = rotation.rotated(transform.basis.z.normalized(), transform.basis.y.signed_angle_to(avg_normal, transform.basis.z) * ground_rot_multi * multi * delta)
		rotation = rotation.rotated(transform.basis.x.normalized(), transform.basis.y.signed_angle_to(avg_normal, transform.basis.x) * ground_rot_multi * multi * delta)
		rotation.y = prev_y

func detect_stick() -> void:
	if air_frames < 15 and !in_hop and !in_bounce:
		var ray_origin := transform.origin
		var ray_end := ray_origin + gravity.normalized() * 1.4
		var ray_result := world.space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 0xFFFFFFFF, [self]))

		if ray_result:
			is_stick = true
			if !grounded:
				grounded = true
				keep_grav = true
			# var distance = ray_result.position.distance_to(ray_origin)
			# Apply stick_speed to stick to ground


func handle_walls() -> void:
	if wall_contacts.size() > 0:
		var avg_normal: Vector3 = Vector3.ZERO
		#var avg_position: Vector3 = Vector3.ZERO
		# print("===")
		for wall: Dictionary in wall_contacts:
			# print(wall["normal"])
			avg_normal += wall["normal"]
			#avg_position += wall["position"]
		avg_normal /= wall_contacts.size()
		#avg_position /= wall_contacts.size()
		# var avg_normal = wall_contacts[-1]["normal"]

		var bonk := false
		var bounce_ratio: float = 0.2
		for wall: Dictionary in wall_contacts:
			var col_obj: Node3D = wall["object"]
			if col_obj.is_in_group("bonk"):
				bonk = true
			if col_obj.get("physics_material_override") and col_obj.physics_material_override.get("bounce"):
				var cur_bounce_ratio: float = col_obj.physics_material_override.bounce
				if cur_bounce_ratio > bounce_ratio:
					bounce_ratio = cur_bounce_ratio
		
		# If we are already moving away from the wall, don't bounce
		var dp := avg_normal.normalized().dot(prev_frame_pre_sim_vel.normalized())

		if dp < 0.25 or (dp < 0 and bonk):
			# Get the component of the linear velocity that is perpendicular to the wall
			var perp_vel := prev_frame_pre_sim_vel.project(avg_normal).length()
			#Debug.print(perp_vel)
			var new_max_speed: float = (1 - abs(dp)) * cur_max_speed
			if perp_vel > min_bounce_speed:
				# print("Bounce ", bounce_ratio)
				# prop_vel = prop_vel.bounce(avg_normal.normalized()) * bounce_ratio
				rest_vel = (prop_vel + rest_vel).bounce(avg_normal.normalized()) * bounce_ratio
				prop_vel = Vector3.ZERO
				prev_prop_vel = prop_vel
				rest_vel += -gravity.normalized() * bounce_force * bounce_ratio
				# linear_velocity = prev_frame_pre_sim_vel.bounce(avg_normal.normalized()) * bounce_ratio
				# if grounded:
				# 	linear_velocity += -gravity.normalized() * bounce_force * bounce_ratio
				grounded = false
				# prev_vel = linear_velocity
				in_bounce = true
				wall_contacts = []
				cur_speed *= -1 * bounce_ratio
			else:
				if prop_vel.length() > new_max_speed:
					prop_vel = prop_vel.normalized() * new_max_speed
					prev_prop_vel = prop_vel
				cur_speed = clamp(cur_speed, -new_max_speed, new_max_speed)
			# print("cur_speed: ", cur_speed)

func handle_contacts(physics_state: PhysicsDirectBodyState3D) -> void:
	for i in range(physics_state.get_contact_count()):
		var collider := physics_state.get_contact_collider_object(i) as Node
		if collider.is_in_group("floor"):
			var col_pos: Vector3 = to_local(physics_state.get_contact_local_position(i))
			if col_pos.y > 0.0:
				continue
			grounded = true
			floor_normals.append(physics_state.get_contact_local_normal(i))
			if in_bounce and bounce_frames > 9:
				in_bounce = false
				bounce_frames = 0
			if in_hop:
				grounded = false
			if in_hop and in_hop_frames > 30:
				grounded = true
				# Switch from hop to drift
				if input_brake:
					# Block hopping
					can_hop = false
				in_hop = false
				in_hop_frames = 0
				if drift_dir == 0:
					in_drift = false
				else:
					in_drift = true
					if outside_drift:
						cur_outside_drift_force = outside_drift_force * (cur_speed / cur_max_speed)
			
			if in_trick:
				in_trick = false
				trick_boost_timer.start(trick_boost_duration)
				#if is_player:
					#Debug.print(["Starting trick boost", trick_boost_timer])
				
		
		if collider.is_in_group("boost"):
			normal_boost_timer.start(normal_boost_duration)
		
		if collider.is_in_group("trick"):
			$TrickTimer.start(trick_cooldown_time)
			trick_boost_timer = normal_boost_timer
			trick_boost_duration = normal_boost_duration
		if collider.is_in_group("small_trick"):
			$TrickTimer.start(trick_cooldown_time)
			trick_boost_timer = small_boost_timer
			trick_boost_duration = small_boost_duration
		
		if collider.is_in_group("offroad"):
			offroad = true
		
		if collider.is_in_group("weak_offroad"):
			weak_offroad = true
		
		if collider.is_in_group("wall"):
			var point := global_position + (transform.basis.y * -vehicle_height_below)
			# var dist_above_floor = transform.basis.y.dot(physics_state.get_contact_local_position(i) - point)
			var dist_above_floor := Util.dist_to_plane(transform.basis.y, point, physics_state.get_contact_local_position(i))

			if dist_above_floor < 0.05 and not collider.is_in_group("bonk"):
				continue

			wall_contacts.append({
				"normal": physics_state.get_contact_local_normal(i),
				"position": physics_state.get_contact_local_position(i),
				"object": collider
			})
		
		if collider.is_in_group("out"):
			if not respawn_stage:
				respawn()
	
	if offroad or weak_offroad:
		offroad_ticks += 1
	else:
		offroad_ticks = 0
	
	if floor_normals.size() > 0:
		var avg_normal: Vector3 = Vector3.ZERO
		for normal: Vector3 in floor_normals:
			avg_normal += normal
		avg_normal /= floor_normals.size()
		floor_normal = avg_normal.normalized()

func get_grounded_vel(delta: float) -> Vector3:
	#print(is_accel, is_brake, steering)
	var hop_vel := Vector3.ZERO
	
	if input_accel and input_brake:
		if cur_speed > min_hop_speed:
			if in_drift:
				cur_speed += get_accel_speed(delta)
			elif can_hop and not in_hop and !is_network:
				do_hop()
			else:
				cur_speed += get_accel_speed(delta)
		else:
			in_drift = false
			drift_gauge = 0.0
			# Decelerate to standstill
			cur_speed += get_brake_speed(delta)
			
			# Check if we can miniturbo
			if abs(cur_speed) <= still_turbo_max_speed:
				# Do miniturbo.
				if grounded and not still_turbo_ready and $StillTurboTimer.is_stopped():
					$StillTurboTimer.start()
					#Debug.print("Start building up miniturbo")
	else:
		if input_accel:
			if still_turbo_ready:
				still_turbo_ready = false
				# Perform miniturbo.
				#Debug.print("Performing miniturbo")
				small_boost_timer.start(small_boost_duration)
				
			cur_speed += get_accel_speed(delta)
		elif input_brake and grounded:
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
	
	# if should_hop:
	# 	in_hop = true
	# 	hop_vel = transform.basis.y * hop_force / (in_hop_frames+1)
	
	var speed_vel := transform.basis.x.normalized() * cur_speed
	
	var vel := speed_vel + hop_vel;
	
	return vel

func is_boost() -> bool:
	if !small_boost_timer.is_stopped() or !normal_boost_timer.is_stopped() or !big_boost_timer.is_stopped():
		return true
	return false

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
	reversing = true
	return -Util.get_vehicle_accel(max_reverse_speed, -cur_speed, reverse_initial_accel, reverse_exponent) * delta


func get_brake_speed(delta: float) -> float:
	var mult := -1.0

	if cur_speed < 0:
		mult = 1.0

	return Util.get_vehicle_accel(max_reverse_speed, abs(abs(cur_speed) - max_reverse_speed), brake_initial_accel, brake_exponent) * delta * mult


func get_friction_speed(delta: float) -> float:
	var mult := -1.0

	if cur_speed < 0:
		mult = 1.0

	return Util.get_vehicle_accel(cur_max_speed, abs(abs(cur_speed) - cur_max_speed), friction_initial_accel, friction_exponent) * delta * mult


func get_boost_speed(delta: float) -> float:
	if in_damage:
		$SmallBoostTimer.stop()
		$NormalBoostTimer.stop()
		$BigBoostTimer.stop()
	
	if not normal_boost_timer.is_stopped():
		# Normal boost is active
		grip_multiplier = 2.0
		return Util.get_vehicle_accel(normal_boost_max_speed, cur_speed, normal_boost_initial_accel, normal_boost_exponent) * delta

	if not small_boost_timer.is_stopped() and not offroad:
		# Small boost is active. Does not work on offroad
		var cur_boost_max_speed := small_boost_max_speed
		if weak_offroad:
			cur_boost_max_speed = max_speed
		grip_multiplier = 2.0
		return Util.get_vehicle_accel(cur_boost_max_speed, cur_speed, small_boost_initial_accel, small_boost_exponent) * delta
	
	if cur_speed > cur_max_speed:
		var speed_range := big_boost_max_speed - cur_max_speed
		var ratio := big_boost_max_speed - cur_speed
		grip_multiplier = 2.0
		return -Util.get_vehicle_accel(speed_range, ratio, friction_initial_accel, friction_exponent) * delta
	return 0

func _on_still_turbo_timer_timeout() -> void:
	#Debug.print("Miniturbo ready")
	still_turbo_ready = true

func handle_vehicle_collisions() -> void:
	var colliding_vehicles: Dictionary = {}
	for shape: ShapeCast3D in %PlayerCollision.get_children():
		shape.force_shapecast_update()
		for i in range(shape.get_collision_count()):
			var collider: Node3D = shape.get_collider(i)
			if collider == self:
				continue
			if collider is Vehicle3:
				if collider not in colliding_vehicles:
					colliding_vehicles[collider] = []
				colliding_vehicles[collider].append(shape.get_collision_point(i))
	
	for col_vehicle: Vehicle3 in colliding_vehicles.keys():
		if col_vehicle in collided_with.keys():
			continue
		
		if prev_frame_pre_sim_vel.length() < col_vehicle.prev_frame_pre_sim_vel.length():
			# Let the other do the work.
			continue
			
		var avg_point: Vector3 = Util.sum(colliding_vehicles[col_vehicle]) / len(colliding_vehicles[col_vehicle])
		
		var my_weight: float = weight * remap(min(prev_frame_pre_sim_vel.length(), 2*max_speed), 0, 2*max_speed, 1.0, 2.0)
		var their_weight: float = col_vehicle.weight * remap(min(col_vehicle.prev_frame_pre_sim_vel.length(), 2*col_vehicle.max_speed), 0, 2*col_vehicle.max_speed, 1.0, 2.0)

		var my_weight_ratio: float = their_weight / my_weight
		var their_weight_ratio: float = my_weight / their_weight
		
		#if is_player:
			#print("weight")
			#print(my_weight, their_weight)
			#print(my_weight_ratio, their_weight_ratio)

		var my_force: float = push_force * my_weight_ratio
		var their_force: float = push_force * their_weight_ratio

		
		var my_dir: Vector3 = Plane(prev_transform.basis.y).project(prev_transform.origin - avg_point).normalized()
		var their_dir: Vector3 = Plane(col_vehicle.prev_transform.basis.y).project(col_vehicle.prev_transform.origin - avg_point).normalized()
		
		apply_push(my_force * my_dir, col_vehicle)
		col_vehicle.apply_push(their_force * their_dir, self)

func apply_push(force: Vector3, vehicle: Vehicle3) -> void:
	if vehicle in collided_with:
		return
	
	collided_with[vehicle] = frame + 10

	rest_vel += force



func respawn() -> void:
	if respawn_stage:
		return
	
	if is_network:
		return
	
	respawn_stage = 1
	remove_item()
	$RespawnTimer.start(respawn_time)
	#world.player_camera.no_move = true
	if is_player:
		world.player_camera.do_respawn()
	cur_progress = -100000

func handle_respawn() -> void:
	freeze = false
	if not respawn_stage:
		return
	
	set_all_input_zero()
	
	if $RespawnTimer.is_stopped():
		respawn_stage = 0
		return
	
	if respawn_stage == 1 and $RespawnTimer.time_left <= respawn_stage2_time:
		# Determine respawn point
		respawn_stage = 2
		var respawn_data: Dictionary = world.get_respawn_point(self)
		respawn_position = respawn_data.position
		respawn_rotation = respawn_data.rotation
		freeze = true
		if is_player:
			world.player_camera.instant = true
			#world.player_camera.no_move = false
			world.player_camera.undo_respawn()
	
	if respawn_stage == 2:
		# Hold vehicle still at respawn point
		set_movement_zero()
		global_position = respawn_position
		global_rotation = respawn_rotation


func handle_particles() -> void:
	handle_drift_particles()
	handle_exhaust_particles()

func handle_exhaust_particles() -> void:
	Util.multi_emit(%ExhaustIdle, false)
	Util.multi_emit(%ExhaustBoost, false)
	
	if is_boost():
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
	elif !$StillTurboTimer.is_stopped():
		Util.multi_emit(%DriftCenterCharging, true)
	elif still_turbo_ready:
		Util.multi_emit(%DriftCenterCharged, true)

func handle_item() -> void:
	if not input_item_just:
		return
	
	if not can_use_item:
		if not $ItemRouletteTimer.is_stopped():
			# User pressed item button while roulette is running.
			var new_time: float = $ItemRouletteTimer.time_left - 0.5
			if new_time < 0:
				$ItemRouletteTimer.stop()
				_on_item_roulette_timer_timeout()
			else:
				$ItemRouletteTimer.start(new_time)
		return
	
	if not item:
		return

	var new_item: ItemBase = item.use(self, world)
	item = new_item
	
	if not item:
		remove_item()
	else:
		can_use_item = true
		if is_player and !is_cpu:
			UI.race_ui.set_item_texture(item.texture)

func remove_item() -> void:
	if item:
		item.queue_free()
		item = null
	can_use_item = false
	if is_player:
		UI.race_ui.hide_roulette()

func get_item(guaranteed_item: PackedScene = null) -> void:
	if is_network:
		return
	
	if respawn_stage:
		return
	
	if item:
		return
	can_use_item = false
	if guaranteed_item:
		item = guaranteed_item.instantiate()
	else:
		var item_rank: int = round(remap(rank, 0, world.players_dict.size(), 0, Global.player_count))
		item = Global.item_dist[item_rank].pick_random().instantiate()
	world.add_child(item)
	$ItemRouletteTimer.start(4)
	if is_player and !is_cpu:
		UI.race_ui.start_roulette()


func _on_item_roulette_timer_timeout() -> void:
	if not item:
		print("Error: Roulette stopped but no item assigned!")
		return
	
	if is_cpu or is_network:
		can_use_item = true
		return
	
	UI.race_ui.stop_roulette(item.texture)

func _on_roulette_stop() -> void:
	can_use_item = true


func _process(delta: float) -> void:
	# UI Stuff
	#if is_multiplayer_authority() and not is_cpu:
		#is_player = true
	handle_input()
	handle_particles()
	handle_item()
	
	if is_player:
		# Update alerts
		for alert_object: Node3D in targeted_by_dict:
			var tex: CompressedTexture2D = targeted_by_dict[alert_object]
			UI.race_ui.update_alert(alert_object, tex, self, world.player_camera, delta)
		
		var spd := linear_velocity.length()
		UI.race_ui.update_speed(spd)
		
		if cur_speed > max_speed:
			extra_fov = (cur_speed - max_speed) * 0.3
		else:
			extra_fov = 0.0
	
		#print(cur_speed)
		#if Engine.get_frames_drawn() % 60 == 0:
			#Debug.print([lap, check_idx, "%.2f" % check_progress, check_key_idx])


func water_entered(area: Area3D) -> void:
	in_water = true
	water_bodies[area] = true


func water_exited(area: Area3D) -> void:
	water_bodies.erase(area)
	if water_bodies.size() == 0:
		in_water = false


#func _on_player_collision_area_entered(area: Area3D):
	#var area_parent = area.get_parent()
	#if not area_parent is Vehicle3:
		#return
	##Debug.print([self, "collided with", area_parent])
	#colliding_vehicles[area_parent] = true
#
#
#func _on_player_collision_area_exited(area):
	#var area_parent = area.get_parent()
	#if not area_parent is Vehicle3:
		#return
	##Debug.print([self, "uncollided with", area_parent])
	#colliding_vehicles.erase(area_parent)
	
#func upload_data():
	#var state: Dictionary = get_state()
	#Network.

func get_state() -> Dictionary:
	update_idx += 1
	return {
		"idx": update_idx,
		"vani": vani.animation,
		"pos": Util.to_array(global_position),
		"rot": Util.to_array(rotation),
		"lin_vel": Util.to_array(linear_velocity),
		"input_accel": input_accel,
		"input_brake": input_brake,
		"input_steer": input_steer,
		"input_trick": input_trick,
		"input_mirror": input_mirror,
		"cur_speed": cur_speed,
		"cur_turn_speed": cur_turn_speed,
		"in_trick": in_trick,
		"in_hop": in_hop,
		"in_hop_frames": in_hop_frames,
		"in_drift": in_drift,
		"drift_dir": drift_dir,
		"drift_gauge": drift_gauge,
		"drift_gauge_max": drift_gauge_max,
		"grounded": grounded,
		"gravity": Util.to_array(gravity),
		"in_bounce": in_bounce,
		"bounce_frames": bounce_frames,
		"prev_frame_pre_sim_vel": Util.to_array(prev_frame_pre_sim_vel),
		"in_water": in_water,
		"respawn_stage": respawn_stage,
		"respawn_time": $RespawnTimer.time_left,
		"check_idx": check_idx,
		"check_key_idx": check_key_idx,
		"check_progress": check_progress,
		"lap": lap,
		"finished": finished,
		"finish_time": finish_time,
		"username": username
	}

func apply_state(state: Dictionary) -> void:
	#var a := [update_idx, state.idx]
	if update_idx > state.idx:
		return
		
	prev_state = state
	
	# Fix up network path point
	var network_path := world.network_path_points[self] as EnemyPath
	cpu_target = network_path
	network_path.global_position = Util.to_vector3(state.pos)
	network_path.rotation = Util.to_vector3(state.rot)
	network_path.normal = network_path.transform.basis.x
	if user_id in world.pings:
		network_path.global_position += network_path.transform.basis.x * state.cur_speed * (1 + ((world.pings[user_id] + world.pings[world.player_user_id])/1000)) * 0.35
	network_path.next_points = [Util.get_path_point_ahead_of_player(world, self)]
	network_path.prev_points = network_path.next_points[0].prev_points
	cpu_target_offset = Vector3.ZERO
	moved_to_next = false
	
	if state.in_hop:
		do_hop()
	if state.in_drift and !in_drift and !state.in_hop:
		do_hop()

	update_idx = state.idx
	vani.animation = state.vani
	cur_speed = state.cur_speed
	cur_turn_speed = state.cur_turn_speed
	grounded = state.grounded
	in_bounce = state.in_bounce
	bounce_frames = state.bounce_frames
	finished = state.finished
	finish_time = state.finish_time
	username = state.username
	input_accel = state.input_accel
	input_brake = state.input_brake
	input_steer = state.input_steer
	input_trick = state.input_trick
	input_mirror = state.input_mirror
	in_trick = state.in_trick
	in_drift = state.in_drift
	drift_dir = state.drift_dir
	drift_gauge = state.drift_gauge
	drift_gauge_max = state.drift_gauge_max
	gravity = Util.to_vector3(state.gravity)
	respawn_stage = state.respawn_stage
	if state.respawn_time:
		$RespawnTimer.start(state.respawn_time)
	
	if global_position.distance_to(Util.to_vector3(state.pos)) > network_teleport_distance:
		global_position = Util.to_vector3(state.pos)
		rotation = Util.to_vector3(state.rot)
		linear_velocity = Util.to_vector3(state.lin_vel)
		prev_frame_pre_sim_vel = Util.to_vector3(state.prev_frame_pre_sim_vel)
		in_water = state.in_water
		check_idx = state.check_idx
		check_key_idx = state.check_key_idx
		check_progress = state.check_progress
		lap = state.lap
		in_hop = state.in_hop
		in_hop_frames = state.in_hop_frames
		teleport(global_position, transform.basis.x, transform.basis.y)
		#Debug.print("TELEPORT!")


func _on_failsafe_timer_timeout() -> void:
	if not finished:
		respawn()

func start_failsafe_timer() -> void:
	if is_player:
		return
	$FailsafeTimer.start()

func damage(damage_type: int) -> void:
	start_failsafe_timer()

	if in_damage:
		return

	in_damage = damage_type
	
	match damage_type:
		DamageType.spin:
			$DamageTimer.start(1.5)
			vani.animation = vani.Type.dmg_spin


func _on_damage_timer_timeout() -> void:
	in_damage = DamageType.none

func set_rank(new_rank: int) -> void:
	if is_player and new_rank != rank:
		UI.race_ui.update_rank(new_rank)
	rank = new_rank

func add_targeted(object: Node3D, tex: CompressedTexture2D) -> void:
	if not object in targeted_by_dict:
		targeted_by_dict[object] = tex

func remove_targeted(object: Node3D) -> void:
	if object in targeted_by_dict:
		targeted_by_dict.erase(object)
		UI.race_ui.remove_alert(object)

func do_hop() -> void:
	# Perform hop for drift
	if in_hop or in_drift:
		return
	in_hop = true
	rest_vel += transform.basis.y * hop_force
	grounded = false
	in_hop_frames = 0
