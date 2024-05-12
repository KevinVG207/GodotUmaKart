extends CharacterBody3D
class_name Vehicle

@export var max_speed: float = 10.0
var max_speed_reversing: float = max_speed * 0.25
@export var accel: float = 6.0
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

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	var forwards_vector = transform.basis.x
	if forwards_vector.normalized().dot(velocity.normalized()) < 0:
		is_backwards = true
	else:
		is_backwards = false
		
	#print("Is backwards: ", is_backwards)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	velocity.x = 0
	velocity.z = 0
		
	var is_accel = Input.is_action_pressed("accelerate")
	var is_brake = Input.is_action_pressed("brake")
	var steering = Input.get_axis("right", "left")
	#print("Steering: ", steering)
	
	if not is_backwards:
		# Vehicle is moving forwards
		if is_accel:
			if not is_brake:
				cur_speed = move_toward(cur_speed, max_speed, accel*delta)
			else:
				# Drift?
				pass
		elif is_brake:
			cur_speed = move_toward(cur_speed, -max_speed_reversing, brake_decel*delta)
		else:
			cur_speed = move_toward(cur_speed, 0.0, idle_decel*delta)
	else:
		# Vehicle is moving backwards
		if is_accel:
			cur_speed = move_toward(cur_speed, max_speed, brake_decel*delta)
		elif is_brake:
			cur_speed = move_toward(cur_speed, -max_speed_reversing, reverse_accel*delta)
		else:
			cur_speed = move_toward(cur_speed, 0.0, idle_decel * delta)
	
	cur_speed = clamp(cur_speed, -max_speed_reversing, max_speed)
	
	#print("Cur_speed: ", cur_speed)
	
	var direction = transform.basis.x
	var accel_vel = direction * cur_speed
	velocity += accel_vel
	
	
	# Steering
	cur_steer = move_toward(cur_steer, max_steer*steering, steer_accel*delta)
	rotate_y(deg_to_rad(cur_steer))
	
	var vel_before_bounce = velocity
	bounce_vector = bounce_vector.move_toward(Vector3.ZERO, bounce_decay*delta)
	velocity += bounce_vector

	var tmp_vel = velocity
	move_and_slide()
	
	var bounced = false
	
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var col_obj = col.get_collider()
		var col_normal = col.get_normal()
		#var angle_difference = Vector2(tmp_vel.x, tmp_vel.z).normalized().dot(Vector2(col_normal.x, col_normal.z).normalized())
		#angle_difference = min(angle_difference + 1, 1)
		var v1 = Vector2(col_normal.x, col_normal.z)
		var v2 = Vector2(tmp_vel.x, tmp_vel.z)
		var angle_to = v2.angle_to(v1)
		var component_along_wall = sin(abs(angle_to)) * v2.length()
		var component_into_wall = abs(cos(abs(angle_to)) * v2.length())

		if col_obj.is_in_group("Wall"):
			if abs(tmp_vel.x) > min_bounce_speed and component_into_wall > min_bounce_component:
				var bounce_ratio = 0.5
				bounced = true
				if col_obj.get("physics_material_override") and col_obj.physics_material_override.get("bounce"):
					bounce_ratio = col_obj.physics_material_override.bounce
				tmp_vel = tmp_vel.bounce(col_normal) * bounce_ratio
			

			if component_along_wall > max_wall_speed:
				var ratio = max_wall_speed / component_along_wall
				print(ratio)
				cur_speed *= ratio
			#var max_wall_speed = max_speed * angle_difference
			#print(max_wall_speed, " ", cur_speed)
			#print("Project: ", tmp_vel.project(col_normal))
			#if cur_speed > max_wall_speed:
				#cur_speed = max_wall_speed
	
	if bounced:
		bounce_vector = (tmp_vel - vel_before_bounce)
	
	#print(bounce_vector.length())
