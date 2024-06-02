extends RigidBody3D

@export var max_speed: float = 10.0
var max_speed_reversing: float = max_speed * 0.25
@export var accel: float = 40.0
var reverse_accel: float = accel * 0.5
var brake_decel: float = 4 * accel
var idle_decel: float = 1.5 * accel
var cur_speed: float = 0.0
var is_backwards: bool = false
var max_steer: float = 2.0
var steer_accel = 50.0
var cur_steer = 0.0
var bounce_vector: Vector3 = Vector3.ZERO
var bounce_decay = 30.0
var min_bounce_speed = max_speed * 0.4
var min_bounce_component = max_speed * 0.25
var max_wall_speed = max_speed * 0.5


func _physics_process(delta):
	var local_velocity = linear_velocity * transform.basis
	print(local_velocity)
	var local_angular_velocity = angular_velocity * transform.basis
	print(local_angular_velocity)
	#var forwards_vector = transform.basis.x
	if local_velocity.x < 0:
		is_backwards = true
	else:
		is_backwards = false
		
	#print("Is backwards: ", is_backwards)
		
	#linear_velocity.x = 0
	#linear_velocity.z = 0
		
	var is_accel = Input.is_action_pressed("accelerate")
	var is_brake = Input.is_action_pressed("brake")
	var steering = Input.get_axis("right", "left")
	
	var new_velocity = local_velocity

	if not is_backwards:
		# Vehicle is moving forwards
		if is_accel:
			if not is_brake:
				#cur_speed = move_toward(cur_speed, max_speed, accel*delta)
				if new_velocity.x < max_speed:
					new_velocity.x = move_toward(new_velocity.x, max_speed, accel*delta)
			else:
				# Drift?
				pass
		elif is_brake:
			#cur_speed = move_toward(cur_speed, -max_speed_reversing, brake_decel*delta)
			if new_velocity.x > -max_speed_reversing:
				new_velocity.x = move_toward(new_velocity.x, -max_speed_reversing, brake_decel*delta)
		else:
			#cur_speed = move_toward(cur_speed, 0.0, idle_decel*delta)
			new_velocity.x = move_toward(new_velocity.x, 0.0, idle_decel*delta)
	else:
		# Vehicle is moving backwards
		if is_accel:
			if new_velocity.x < max_speed:
				new_velocity.x = move_toward(new_velocity.x, max_speed, brake_decel*delta)
			#cur_speed = move_toward(cur_speed, max_speed, brake_decel*delta)
		elif is_brake:
			if new_velocity.x > -max_speed_reversing:
				new_velocity.x = move_toward(new_velocity.x, -max_speed_reversing, reverse_accel*delta)
			#cur_speed = move_toward(cur_speed, -max_speed_reversing, reverse_accel*delta)
		else:
			new_velocity.x = move_toward(new_velocity.x, 0.0, idle_decel*delta)
			#cur_speed = move_toward(cur_speed, 0.0, idle_decel * delta)
	
	#cur_speed = clamp(cur_speed, -max_speed_reversing, max_speed)
	
	#print("Cur_speed: ", cur_speed)
	
	#var direction = transform.basis.x
	#var accel_vel = direction * cur_speed
	linear_velocity = transform.basis.x * new_velocity.x + transform.basis.y * new_velocity.y + transform.basis.z * new_velocity.z
	#constant_force
	
	
	cur_steer = move_toward(cur_steer, max_steer*steering, steer_accel*delta)
	# Rotate angular velocity based on steering degrees
	rotate_y(deg_to_rad(cur_steer))

	# new_velocity = new_velocity.rotated(transform.basis.y, deg_to_rad(cur_steer))

	# linear_velocity = transform.basis.x * new_velocity.x + transform.basis.y * new_velocity.y + transform.basis.z * new_velocity.z


	# local_angular_velocity.y = cur_steer

	# angular_velocity = transform.basis.x * local_angular_velocity.x + transform.basis.y * local_angular_velocity.y + transform.basis.z * local_angular_velocity.z
	#rotate_y(deg_to_rad(cur_steer))
