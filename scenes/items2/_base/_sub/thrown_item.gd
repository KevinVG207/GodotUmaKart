extends DetachedItem

class_name ThrownItem

@export var body: RigidBody3D
@export var area: Area3D

var landed: bool = false

func _ready() -> void:
	super()
	body._integrate_forces.bind()
	area.body_entered.connect(_on_area_3d_body_entered)
	
	var offset: Vector3 = origin.transform.basis.z * (origin.vehicle_length_ahead * 1)
	var dir_multi: float = 1.0
	if origin.input.tilt < 0:
		dir_multi = -1.0
		offset = -origin.transform.basis.z * (origin.vehicle_length_behind * 2)
	
	var direction := origin.transform.basis.z * dir_multi

	var throw_force := origin.linear_velocity
	if dir_multi > 0:
		offset += origin.transform.basis.y * 0.5
		var multi: float = 1.0
		if origin.in_hop:
			multi = 1.5
		throw_force += ((direction * 1.5) + (origin.transform.basis.y * 1.0)) * 13 * multi
	else:
		throw_force += -origin.global_transform.basis.z.normalized() * 3

	body.global_rotation = origin.global_rotation
	body.global_position = origin.global_position + offset

	body.linear_velocity = throw_force

func _integrate_forces(physics_state: PhysicsDirectBodyState3D) -> void:
	var delta: float = physics_state.step
	
	if body.global_position.y < world.fall_failsafe:
		destroy()
		return
	
	if landed:
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		gravity = Vector3.ZERO
		return
	
	for i in range(physics_state.get_contact_count()):
		var collider := Util.get_contact_collision_shape(physics_state, i)
		if collider.is_in_group("col_floor"):
			# Floor touched! Snap to it and land.
			landed = true
			var normal: Vector3 = physics_state.get_contact_local_normal(i)
			var ray_start := body.global_position + normal.normalized() * 0.5
			var ray_end := body.global_position - normal.normalized() * 1.0
			var ray_res: Dictionary = Util.raycast_for_group(world.space_state, ray_start, ray_end, "floor", [self])
			var land_loc := physics_state.get_contact_local_position(i)
			var land_normal := normal
			if ray_res:
				land_loc = ray_res.position
				land_normal = ray_res.normal
			
			body.global_position = land_loc
			
			# Rotate the object so our transform.basis.y matches the land_normal.
			body.global_transform = Util.align_with_y(body.global_transform, land_normal)
			
			body.linear_velocity = Vector3.ZERO
			body.angular_velocity = Vector3.ZERO
			world.send_item_state(self)
			return

	body.linear_velocity += gravity * delta * 2

	if body.linear_velocity.normalized().dot(gravity.normalized()) > 0:
		var vel_along_gravity := body.linear_velocity.project(gravity)
		# Apply terminal velocity
		if Util.v3_length_compare(vel_along_gravity, 20) > 0:
			body.linear_velocity = body.linear_velocity - vel_along_gravity + gravity.normalized() * 20
	
	body.angular_velocity = Vector3.ZERO

func get_state() -> Dictionary:
	return {
		"p": Util.to_array(body.global_position),
		"r": Util.to_array(body.global_rotation),
		"v": Util.to_array(body.linear_velocity),
		"g": Util.to_array(gravity),
		"l": landed
	}
	
func set_state(state: Dictionary) -> void:
	body.global_position = Util.to_vector3(state.p)
	body.global_rotation = Util.to_vector3(state.r)
	body.linear_velocity = Util.to_vector3(state.v)
	gravity = Util.to_vector3(state.g)
	landed = state.l

func _on_area_3d_body_entered(body: Variant) -> void:
	if body == self:
		return
	if body is PhysicalItem:
		var item := body as PhysicalItem
		destroy()
		item.destroy()
		return
	
	if not body is Vehicle4:
		return
	
	var vehicle := body as Vehicle4
	
	if vehicle.is_network:
		return
	
	if vehicle == origin and grace_ticks > 0:
		return
	
	vehicle.damage(Vehicle4.DamageType.SPIN)
	destroy()
