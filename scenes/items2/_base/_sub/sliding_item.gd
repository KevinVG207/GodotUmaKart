extends DetachedItem

class_name SlidingItem

@export var body: CharacterBody3D
@export var area: Area3D

@export var target_speed: float = 40.0
@export var break_on_wall := false

func _ready() -> void:
	super()
	area.body_entered.connect(_on_area_3d_body_entered)
	
	if Global.MODE1 == Global.MODE1_ONLINE:
		area.set_collision_mask_value(3, false)
	var offset := origin.transform.basis.z * (origin.vehicle_length_ahead * 2)
	var dir_multi: float = 1.0
	if origin.input.tilt < 0:
		dir_multi = -1.0
		offset = -origin.transform.basis.z * (origin.vehicle_length_behind * 2)
	var direction := origin.transform.basis.z * dir_multi
	
	body.global_position = origin.global_position + offset

	# Subtract component of direction along gravity
	direction = direction - direction.project(gravity.normalized())
	direction = direction.normalized()

	var speed: float = max(0, origin.linear_velocity.project(direction).length()) + 5
	
	body.look_at(body.global_position + direction, -gravity)
	body.velocity = direction * speed

func _physics_process(delta: float) -> void:
	super(delta)
	
	if body.global_position.y < world.fall_failsafe:
		destroy()
		return
	
	body.up_direction = -gravity
	
	var speed := body.velocity.length()
	var new_speed := move_toward(speed, target_speed, delta * 30)
	var ratio := new_speed / speed
	body.velocity *= ratio
	
	body.velocity += gravity * delta * 2
	
	body.up_direction = -gravity.normalized()
	body.move_and_slide()
	
	if body.is_on_floor():
		body.velocity = body.velocity - body.velocity.project(gravity)
	
	if Util.v3_length_compare(body.velocity, 0.01) < 0:
	# if velocity.length() < 0.01:
		body.velocity = Vector3(0.1, 0.1, 0.1)
	
	body.look_at(body.global_position + body.velocity.normalized(), -gravity.normalized())

	for i in body.get_slide_collision_count():
		var col_data := body.get_slide_collision(i)
		var collider := Util.get_collision_shape(col_data, 0)
		if collider == null:
			continue
		
		if collider.is_in_group("col_wall"):
			if break_on_wall:
				destroy()
				return
			# Bounce off walls
			var normal := col_data.get_normal(0)
			if Util.v3_length_compare(body.velocity, 0.1) > 0 and body.velocity.normalized().dot(normal) < 0:
			# if velocity.length() > 0.1 and velocity.normalized().dot(normal) < 0:
				body.velocity = body.velocity.bounce(normal)
				body.velocity = body.velocity - body.velocity.project(gravity.normalized())
			break

func get_state() -> Dictionary:
	return {
		"p": Util.to_array(body.global_position),
		"r": Util.to_array(body.global_rotation),
		"v": Util.to_array(body.velocity),
		"g": Util.to_array(gravity)
	}
	
func set_state(state: Dictionary) -> void:
	body.global_position = Util.to_vector3(state.p)
	body.global_rotation = Util.to_vector3(state.r)
	body.velocity = Util.to_vector3(state.v)
	gravity = Util.to_vector3(state.g)
	return

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
