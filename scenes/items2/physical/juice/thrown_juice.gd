extends ThrownItem

class_name ThrownJuice

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
			destroy()
			if Global.MODE1 == Global.MODE1_OFFLINE or owned_by == world.player_vehicle:
				var spill := world.make_physical_item("JuiceSpill", owned_by) as JuiceSpill
				spill.body.global_transform = body.global_transform
				spill.is_ready = true
				world.send_item_state(spill)
			return

	body.linear_velocity += gravity * delta * 2

	if body.linear_velocity.normalized().dot(gravity.normalized()) > 0:
		var vel_along_gravity := body.linear_velocity.project(gravity)
		# Apply terminal velocity
		if Util.v3_length_compare(vel_along_gravity, 20) > 0:
			body.linear_velocity = body.linear_velocity - vel_along_gravity + gravity.normalized() * 20
	
	body.angular_velocity = Vector3.ZERO
