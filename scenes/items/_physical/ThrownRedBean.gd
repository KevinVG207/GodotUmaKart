extends CharacterBody3D

var physical_item = true
var item_id: String
var owner_id: String
var world: RaceBase
var no_updates: bool = false

var gravity: Vector3
var start_speed: float = 30.0
var target_speed: float = start_speed
var despawn_time: float = 30.0
var grace_frames: int = 10
var cur_grace: int = 0

const TargetMode = {
	none = 0,
	follow = 1,
	homing = 2
}
var target_mode: int = TargetMode.follow
var target_player: Vehicle3 = null
var target_point: EnemyPath
var target_pos: Vector3
var dist_to_homing: float = 20.0

func _enter_tree():
	if Global.MODE1 == Global.MODE1_ONLINE:
		$Area3D.set_collision_mask_value(3, false)
	var thrower = world.players_dict[owner_id] as Vehicle3
	gravity = thrower.gravity
	var offset = thrower.transform.basis.x * (thrower.vehicle_length_ahead * 2)
	var dir_multi = 1.0
	if thrower.input_updown < 0:
		target_mode = TargetMode.none
		dir_multi = -1.0
		offset = -thrower.transform.basis.x * (thrower.vehicle_length_behind * 2)
	var direction = thrower.transform.basis.x * dir_multi
	
	global_position = thrower.global_position + offset

	# Subtract component of direction along gravity
	direction = direction - direction.project(gravity.normalized())
	direction = direction.normalized()

	var speed = max(0, thrower.linear_velocity.project(direction).length()) + 5
	
	look_at(global_position + direction, -gravity)
	velocity = direction * speed
	
	# Find the target player
	var target_rank = thrower.rank - 1
	if target_rank < 0:
		target_rank = world.players_dict.size() - 1
	
	for v: Vehicle3 in world.players_dict.values():
		if v.rank == target_rank:
			target_player = v
			break

func _ready():
	$DespawnTimer.start(despawn_time)

func _physics_process(delta):
	if item_id in world.deleted_physical_items:
		self.queue_free()
		return
	
	#if !target_player or target_player == world.player_vehicle:
		#world.destroy_physical_item(item_id)
		#return
		
	if not target_point:
		# Determine the target point currently in front of the target player.
		target_point = Util.get_path_point_ahead_of_player(world, world.players_dict[owner_id])
	
	var dist_to_target_player = global_position.distance_to(target_player.global_position)
	if target_mode == TargetMode.follow and dist_to_target_player < dist_to_homing and owner_id == world.player_user_id:
		target_mode = TargetMode.homing
	
	match target_mode:
		TargetMode.homing:
			owner_id = target_player.user_id
			target_pos = target_player.global_position
			target_speed = remap(clamp(dist_to_target_player, 0.0, 20.0), 0.0, 20.0, target_player.linear_velocity.length(), start_speed)
	
		TargetMode.follow:
			# First, change the target player.
			var targets: Array = world.players_dict.values()
			targets.erase(world.players_dict[owner_id])
			
			if targets:
				targets.sort_custom(func(a,b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
				target_player = targets[0]
				
				var dist_to_target = global_position.distance_to(target_point.global_position)
				if dist_to_target < target_point.dist:
					target_point = target_point.next_points.pick_random()
				
				target_pos = target_point.global_position
	
	if target_pos:
		# Determine which side to steer
		var target_dir = (target_pos - global_position).normalized()
		var angle = transform.basis.x.angle_to(target_dir) - PI/2
		var is_behind = transform.basis.z.dot(target_dir) < 0

		if is_behind:
			if angle < 0:
				angle -= 10
			else:
				angle += 10
		
		var turn_speed = 1.0
		if angle < 0:
			turn_speed *= -1
		velocity = velocity.rotated(transform.basis.y, turn_speed * delta * 3)
	
	var speed = velocity.length()
	var new_speed = move_toward(speed, target_speed, delta * 30)
	var ratio = new_speed / speed
	velocity *= ratio
	
	velocity += gravity * delta * 2
	
	up_direction = -gravity.normalized()
	move_and_slide()
	
	if is_on_floor():
		velocity = velocity - velocity.project(gravity)
	
	if velocity.length() < 0.01:
		velocity = Vector3(0.1, 0.1, 0.1)
	
	look_at(global_position + velocity.normalized(), -gravity.normalized())

	for i in get_slide_collision_count():
		var col_data = get_slide_collision(i)
		var collider = col_data.get_collider(0)
		if collider.is_in_group("wall"):
			# Break on walls
			if owner_id == world.player_user_id:
				world.destroy_physical_item(item_id)
			
			#var normal = col_data.get_normal(0)
			#if velocity.length() > 0.1 and velocity.normalized().dot(normal) < 0:
				#velocity = velocity.bounce(normal)
				#velocity = velocity - velocity.project(gravity.normalized())
	
	cur_grace += 1


func get_state() -> Dictionary:
	return {
		"pos": Util.to_array(global_position),
		"rot": Util.to_array(global_rotation),
		"velocity": Util.to_array(velocity),
		"gravity": Util.to_array(gravity),
		"target_mode": target_mode,
		"owner_id": owner_id
	}
	
func set_state(state: Dictionary):
	global_position = Util.to_vector3(state.pos)
	global_rotation = Util.to_vector3(state.rot)
	velocity = Util.to_vector3(state.velocity)
	gravity = Util.to_vector3(state.gravity)
	target_mode = state.target_mode
	owner_id = state.owner_id
	return


func _on_despawn_timer_timeout():
	world.destroy_physical_item(item_id)


func _on_area_3d_body_entered(body):
	if body == self:
		return
	if "physical_item" in body:
		world.destroy_physical_item(item_id)
		world.destroy_physical_item(body.item_id)
		return
	
	if not body is Vehicle3:
		return
	
	if body == world.players_dict[owner_id] and cur_grace <= grace_frames:
		return
	
	body.damage(Vehicle3.DamageType.spin)
	world.destroy_physical_item(item_id)
