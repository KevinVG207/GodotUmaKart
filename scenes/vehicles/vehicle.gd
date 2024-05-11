extends CharacterBody3D


@export var max_speed: float = 10.0
@export var max_speed_reversing: float = 4.0
@export var accel: float = 1.0
@export var reverse_accel: float = 0.5
@export var brake_decel: float = 3.0
@export var idle_decel: float = 2.0
var cur_speed: float = 0.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	velocity.x = 0
	velocity.z = 0
		
	var is_accel = Input.is_action_pressed("accelerate")
	var is_brake = Input.is_action_pressed("brake")
	
	if is_accel:
		if not is_brake:
			#cur_speed += accel * delta
			cur_speed = move_toward(cur_speed, max_speed, accel*delta)
		else:
			# Drift?
			pass
	elif is_brake:
		var tmp = cur_speed
		cur_speed -= reverse_accel * delta
		if cur_speed > 0:
			cur_speed -= brake_decel * delta
		#cur_speed = move_toward(cur_speed, 0, brake_decel*delta)
	else:
		#cur_speed -= idle_decel * delta
		#cur_speed = clamp(cur_speed, 0, max_speed)
		cur_speed = move_toward(cur_speed, 0.0, idle_decel * delta)
	
	cur_speed = clamp(cur_speed, -max_speed_reversing, max_speed)
	
	print(cur_speed)
	
	var direction = transform.basis.x
	var accel_vel = direction * cur_speed
	velocity += accel_vel
	

	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#if direction:
		#velocity.x = direction.x * SPEED
		#velocity.z = direction.z * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
