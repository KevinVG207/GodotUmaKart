extends RigidBody3D

var physical_item := true
var item_id: String
var owner_id: String
var world: RaceBase
var no_updates: bool = true

var gravity: Vector3
var landed: bool = false

var grace_frames: int = 30
var cur_grace: int = 0

func _enter_tree() -> void:
	var thrower := world.players_dict[owner_id] as Vehicle4
	gravity = thrower.gravity
	var offset: Vector3 = thrower.transform.basis.z * (thrower.vehicle_length_ahead * 1)
	var dir_multi: float = 1.0
	if thrower.input.tilt < 0:
		dir_multi = -1.0
		offset = -thrower.transform.basis.z * (thrower.vehicle_length_behind * 2)
	
	var direction := thrower.transform.basis.z * dir_multi

	var throw_force := thrower.linear_velocity
	if dir_multi > 0:
		offset += thrower.transform.basis.y * 0.5
		var multi: float = 1.0
		if thrower.in_hop:
			multi = 1.5
		throw_force += ((direction * 1.5) + (thrower.transform.basis.y * 1.0)) * 13 * multi
	else:
		throw_force += -thrower.global_transform.basis.z.normalized() * 3

	global_rotation = thrower.global_rotation
	global_position = thrower.global_position + offset

	linear_velocity = throw_force

func _ready() -> void:
	$DespawnTimer.start()


func _integrate_forces(physics_state: PhysicsDirectBodyState3D) -> void:
	var delta: float = physics_state.step
	cur_grace += 1
	
	if landed:
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		gravity = Vector3.ZERO
		return
	
	for i in range(physics_state.get_contact_count()):
		var collider := physics_state.get_contact_collider_object(i) as Node
		if collider.is_in_group("col_floor"):
			# Floor touched! Snap to it and land.
			landed = true
			cur_grace += grace_frames
			$DespawnTimer.stop()
			var normal: Vector3 = physics_state.get_contact_local_normal(i)
			var ray_start := global_position + normal.normalized() * 0.5
			var ray_end := global_position - normal.normalized() * 1.0
			var ray_res: Dictionary = Util.raycast_for_group(world.space_state, ray_start, ray_end, "floor", [self])
			var land_loc := physics_state.get_contact_local_position(i)
			var land_normal := normal
			if ray_res:
				land_loc = ray_res.position
				land_normal = ray_res.normal
			
			global_position = land_loc
			
			# Rotate the object so our transform.basis.y matches the land_normal.
			# Rotate along Z axis until it lines up reasonably well.
			global_transform = Util.align_with_y(global_transform, land_normal)
			
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
			world.send_item_state(self)
			return
	

	
	linear_velocity += gravity * delta * 2

	if linear_velocity.normalized().dot(gravity.normalized()) > 0:
		var vel_along_gravity := linear_velocity.project(gravity)
		# Apply terminal velocity
		if vel_along_gravity.length() > 20:
			linear_velocity = linear_velocity - vel_along_gravity + gravity.normalized() * 20
	
	angular_velocity = Vector3.ZERO


func get_state() -> Dictionary:
	return {
		"pos": Util.to_array(global_position),
		"rot": Util.to_array(global_rotation),
		"vel": Util.to_array(linear_velocity),
		"gravity": Util.to_array(gravity),
		"landed": landed
	}
	
func set_state(state: Dictionary) -> void:
	global_position = Util.to_vector3(state.pos)
	global_rotation = Util.to_vector3(state.rot)
	linear_velocity = Util.to_vector3(state.vel)
	gravity = Util.to_vector3(state.gravity)
	landed = state.landed
	return


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == self:
		return
	if "physical_item" in body:
		world.destroy_physical_item(item_id)
		world.destroy_physical_item(body.item_id)
		return
	
	if not body is Vehicle4:
		return
	
	var vehicle := body as Vehicle4
	
	if vehicle.is_network:
		return
	
	if vehicle == world.players_dict[owner_id] and cur_grace <= grace_frames:
		return
	
	vehicle.damage(Vehicle4.DamageType.SPIN)
	world.destroy_physical_item(item_id)


func _on_despawn_timer_timeout() -> void:
	world.destroy_physical_item(item_id)
