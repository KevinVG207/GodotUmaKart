extends CharacterBody3D

var physical_item := true
var item_id: String
var owner_id: String
var world: RaceBase
var no_updates: bool = false

var gravity: Vector3
var turn_speed: float = 4.5
var start_speed: float = 50.0
var target_speed: float = start_speed
var despawn_time: float = 30.0
var grace_frames: int = 30
var cur_grace: int = 0
@export var target_texture: CompressedTexture2D

const TargetMode = {
	none = 0,
	follow = 1,
	homing = 2
}
var target_mode: int = TargetMode.follow
var target_player: Vehicle3 = null:
	set(value):
		if value != target_player:
			value.add_targeted(self, target_texture)
			if target_player:
				target_player.remove_targeted(self)
		target_player = value
var target_point: EnemyPath
var target_pos: Vector3
var dist_to_homing: float = 20.0
var new_owner: String = ""

func _enter_tree() -> void:
	if Global.MODE1 == Global.MODE1_ONLINE:
		$Area3D.set_collision_mask_value(3, false)
	var thrower := world.players_dict[owner_id] as Vehicle3
	gravity = thrower.gravity
	var offset := thrower.transform.basis.x * (thrower.vehicle_length_ahead * 2)
	var dir_multi: float = 1.0
	if thrower.input_updown < 0:
		target_mode = TargetMode.none
		dir_multi = -1.0
		offset = -thrower.transform.basis.x * (thrower.vehicle_length_behind * 2)
	var direction := thrower.transform.basis.x * dir_multi
	
	global_position = thrower.global_position + offset

	# Subtract component of direction along gravity
	direction = direction - direction.project(gravity.normalized())
	direction = direction.normalized()

	var speed: float = max(thrower.max_speed / 4, thrower.linear_velocity.project(direction).length()) + 3
	
	look_at(global_position + direction, -gravity)
	velocity = direction * speed
	
	# Find the target player
	var target_rank: int = thrower.rank - 1
	if target_rank < 0:
		target_rank = world.players_dict.size() - 1
	
	for v: Vehicle3 in world.players_dict.values():
		if v.rank == target_rank:
			target_player = v
			break

func _ready() -> void:
	$DespawnTimer.start(despawn_time)

func _physics_process(delta: float) -> void:
	if item_id in world.deleted_physical_items:
		self.queue_free()
		return
	
	#if !target_player or target_player == world.player_vehicle:
		#world.destroy_physical_item(item_id)
		#return
		
	if not target_point:
		# Determine the target point currently in front of the thrower.
		target_point = Util.get_path_point_ahead_of_player(world.players_dict[owner_id])
	
	var dist_to_target_player: float = 10000
	if target_player:
		dist_to_target_player = global_position.distance_to(target_player.global_position)
		if target_mode == TargetMode.follow and dist_to_target_player < dist_to_homing and (Global.MODE1 == Global.MODE1_OFFLINE or (Global.MODE1 == Global.MODE1_ONLINE and owner_id == world.player_user_id)):
			target_mode = TargetMode.homing
			new_owner = target_player.user_id
			#print("SETTING OWNER: ", new_owner)
	
	match target_mode:
		TargetMode.homing:
			target_pos = target_player.global_position
			target_speed = remap(clamp(dist_to_target_player, 0.0, 20.0), 0.0, 20.0, max(target_player.max_speed/2, target_player.prop_vel.length()), start_speed)
	
		TargetMode.follow:
			# First, change the target player.
			var targets: Array = world.players_dict.values()
			targets.erase(world.players_dict[owner_id])
			
			if targets:
				targets.sort_custom(func(a: Vehicle3, b: Vehicle3) -> bool: return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
				target_player = targets[0]
				
				var dist_to_target := global_position.distance_to(target_point.global_position)
				if dist_to_target < target_point.dist:
					target_point = world.pick_next_point_to_target(target_point, Util.get_path_point_ahead_of_player(target_player))
				
			target_pos = target_point.global_position
	
	if target_pos:
		# Determine which side to steer
		var target_dir := (target_pos - global_position).normalized()
		var angle := transform.basis.x.angle_to(target_dir) - PI/2
		var is_behind := transform.basis.z.dot(target_dir) < 0

		if is_behind:
			if angle < 0:
				angle -= 10
			else:
				angle += 10
		
		var cur_turn_speed: float = turn_speed
		if angle < 0:
			cur_turn_speed *= -1
		
		if dist_to_target_player < 10:
			cur_turn_speed *= 2
		
		velocity = velocity.rotated(transform.basis.y, cur_turn_speed * delta)
	
	var speed := velocity.length()
	var new_speed := move_toward(speed, target_speed, delta * 30)
	var ratio := new_speed / speed
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
		var col_data := get_slide_collision(i)
		var collider := col_data.get_collider(0)
		if collider.is_in_group("wall"):
			# Break on walls
			var col_pos: Vector3 = to_local(col_data.get_position())
			if col_pos.y >= 0.1:
				if owner_id == world.player_user_id or Global.MODE1 == Global.MODE1_OFFLINE:
					world.destroy_physical_item(item_id)
			
			#var normal = col_data.get_normal(0)
			#if velocity.length() > 0.1 and velocity.normalized().dot(normal) < 0:
				#velocity = velocity.bounce(normal)
				#velocity = velocity - velocity.project(gravity.normalized())
	
	cur_grace += 1


func get_state() -> Dictionary:
	var _owner_id := owner_id
	if new_owner:
		_owner_id = new_owner
		new_owner = ""
	
	return {
		"pos": Util.to_array(global_position),
		"rot": Util.to_array(global_rotation),
		"velocity": Util.to_array(velocity),
		"gravity": Util.to_array(gravity),
		"target_mode": target_mode,
		"owner_id": _owner_id
	}
	
func set_state(state: Dictionary) -> void:
	global_position = Util.to_vector3(state.pos)
	global_rotation = Util.to_vector3(state.rot)
	velocity = Util.to_vector3(state.velocity)
	gravity = Util.to_vector3(state.gravity)
	target_mode = state.target_mode
	owner_id = state.owner_id
	return

func _exit_tree() -> void:
	# Remove target indicator
	if target_player:
		target_player.remove_targeted(self)

func _on_despawn_timer_timeout() -> void:
	world.destroy_physical_item(item_id)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == self:
		return
	if "physical_item" in body:
		world.destroy_physical_item(item_id)
		world.destroy_physical_item(body.item_id)
		return
	
	if not body is Vehicle3:
		return
	
	if body.is_network:
		return
	
	if body == world.players_dict[owner_id] and cur_grace <= grace_frames:
		return
	
	body.damage(Vehicle3.DamageType.spin)
	world.destroy_physical_item(item_id)
