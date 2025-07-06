extends SlidingItem

class_name ThrownRedBean

var turn_speed: float = 4.5
@export var start_speed: float = 50.0
@export var target_texture: CompressedTexture2D

enum TargetMode {
	NONE,
	FOLLOW,
	HOMING
}

var target_mode: int = TargetMode.FOLLOW
var target_player: Vehicle4 = null:
	set(value):
		if value != target_player:
			value.add_targeted(body, target_texture)
			if target_player:
				target_player.remove_targeted(body)
		target_player = value
var target_point: EnemyPath
var target_pos: Vector3
var dist_to_homing: float = 30.0

func _ready() -> void:
	super()
	var offset := origin.transform.basis.z * (origin.vehicle_length_ahead * 2)
	var dir_multi: float = 1.0
	if origin.input.tilt < 0:
		target_mode = TargetMode.NONE
		dir_multi = -1.0
		offset = -origin.transform.basis.z * (origin.vehicle_length_behind * 2)
	var direction := origin.transform.basis.z * dir_multi
	
	body.global_position = origin.global_position + offset

	# Subtract component of direction along gravity
	direction = direction - direction.project(gravity.normalized())
	direction = direction.normalized()

	var speed: float = max(origin.max_speed / 4, origin.linear_velocity.project(direction).length()) + 3
	
	body.look_at(body.global_position + direction, -gravity)
	body.velocity = direction * speed
	
	# Find the target player
	var target_rank: int = origin.rank - 1
	if target_rank < 0:
		target_rank = world.players_dict.size() - 1
	
	for v: Vehicle4 in world.players_dict.values():
		if v.rank == target_rank:
			target_player = v
			break

func _physics_process(delta: float) -> void:
	if not target_point:
		# Determine the target point currently in front of the thrower.
		target_point = Util.get_path_point_ahead_of_player(origin)

	var dist_to_target_player: float = 10000
	if target_player:
		dist_to_target_player = body.global_position.distance_to(target_player.global_position)
		if target_mode == TargetMode.FOLLOW and dist_to_target_player < dist_to_homing and (Global.MODE1 == Global.MODE1_OFFLINE or (Global.MODE1 == Global.MODE1_ONLINE and owned_by == world.player_vehicle)):
			target_mode = TargetMode.HOMING
			if owned_by == world.player_vehicle and Global.MODE1 == Global.MODE1_ONLINE and target_player != world.player_vehicle:
				world.item_transfer_owner(self, target_player.user_id)
	
	match target_mode:
		TargetMode.HOMING:
			target_pos = target_player.global_position
			target_speed = remap(clamp(dist_to_target_player, 0.0, 20.0), 0.0, 20.0, max(target_player.max_speed/2, target_player.velocity.prop_vel.length()), start_speed)
			if is_transferring_ownership:
				target_speed = max(target_player.velocity.prop_vel.length(), 1.0)
	
		TargetMode.FOLLOW:
			# First, change the target player.
			var targets: Array = world.players_dict.values()

			if grace_ticks > 0:
				targets.erase(world.players_dict[owner_id])
			
			if targets:
				targets.sort_custom(func(a: Vehicle4, b: Vehicle4) -> bool: return body.global_position.distance_to(a.global_position) < body.global_position.distance_to(b.global_position))
				target_player = targets[0]
				
				var dist_to_target := body.global_position.distance_to(target_point.global_position)
				if dist_to_target < target_point.dist:
					target_point = world.pick_next_point_to_target(target_point, Util.get_path_point_ahead_of_player(target_player))
				
			target_pos = target_point.global_position
	
	if target_pos:
		# Determine which side to steer
		var target_dir := (target_pos - body.global_position).normalized()
		var angle := body.transform.basis.x.angle_to(target_dir) - PI/2
		var is_behind := body.transform.basis.z.dot(target_dir) < 0

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
		
		body.velocity = body.velocity.rotated(body.transform.basis.y, cur_turn_speed * delta)
		
		if target_mode == TargetMode.HOMING:
			body.velocity = target_dir.normalized() * body.velocity.length()
	
	super(delta)

func on_destroy() -> void:
	if target_player:
		target_player.remove_targeted(body)

func get_state() -> Dictionary:
	var out := {
		"p": Util.to_array(body.global_position),
		"r": Util.to_array(body.global_rotation),
		"v": Util.to_array(body.velocity),
		"g": Util.to_array(gravity),
		"m": target_mode,
		"t": target_player.user_id if target_player else null
	}
	return out
	
func set_state(state: Dictionary) -> void:
	var update_pos := true
	if target_player:
		var dist_to_vector := (target_pos - body.global_position).length_squared()
		var translation_dist := (Util.to_vector3(state.p) - body.global_position).length_squared()
		if translation_dist > dist_to_vector:
			update_pos = false
	
	if update_pos:
		body.global_position = Util.to_vector3(state.p)
		body.global_rotation = Util.to_vector3(state.r)
		body.velocity = Util.to_vector3(state.v)
		gravity = Util.to_vector3(state.g)
	
	if target_mode != TargetMode.HOMING:
		target_mode = state.m
	
	if state.t:
		target_player = world.players_dict[state.t]

func _on_owner_changed(old_owner: Vehicle4, new_owner: Vehicle4) -> void:
	super(old_owner, new_owner)
	grace_ticks = -1
