extends CharacterBody3D

var item_id: String
var owner_id: String
var world: RaceBase

var gravity: Vector3
var direction: Vector3
var target_speed: float = 25.0
var despawn_time: float = 30.0
var grace_frames: int = 10
var cur_grace: int = 0

func _enter_tree():
	if Global.MODE1 == Global.MODE1_ONLINE:
		$Area3D.set_collision_mask_value(3, false)
	var thrower = world.players_dict[owner_id] as Vehicle3
	gravity = thrower.gravity
	var offset = thrower.transform.basis.x * (thrower.vehicle_length_ahead * 2)
	var dir_multi = 1.0
	if thrower.input_updown < 0:
		dir_multi = -1.0
		offset = -thrower.transform.basis.x * (thrower.vehicle_length_behind * 2)
	direction = thrower.transform.basis.x * dir_multi
	
	global_position = thrower.global_position + offset

	# Subtract component of direction along gravity
	direction = direction - direction.project(gravity.normalized())
	direction = direction.normalized()

	var speed = max(0, thrower.linear_velocity.project(direction).length()) + 5
	
	look_at(global_position + direction, -gravity)
	velocity = direction * speed

func _ready():
	$DespawnTimer.start(despawn_time)

func _physics_process(delta):
	var speed = velocity.length()
	var new_speed = move_toward(speed, target_speed, delta * 10)
	var ratio = new_speed / speed
	velocity *= ratio
	
	velocity += gravity * delta * 5
	
	#var ray_result = Util.raycast_for_group(self, global_position, global_position + gravity.normalized() * 1.5, "floor", [self])
	#if not ray_result:
		#velocity += gravity * delta * 10
	#else:
		#velocity += gravity * delta * 30
	
	look_at(global_position + direction, -gravity)
	up_direction = -gravity.normalized()
	move_and_slide()
	
	if is_on_floor():
		velocity = velocity - velocity.project(gravity)

	for i in get_slide_collision_count():
		var col_data = get_slide_collision(i)
		var collider = col_data.get_collider(0)
		if collider.is_in_group("wall"):
			# Bounce off walls
			var normal = col_data.get_normal(0)
			velocity = velocity.bounce(normal)
	print(velocity)
	
	cur_grace += 1


func get_state() -> Dictionary:
	return {}
	
func set_state(state: Dictionary):
	return


func _on_despawn_timer_timeout():
	world.destroy_physical_item(item_id)


func _on_area_3d_body_entered(body):
	print(body)
	if not body is Vehicle3:
		print("Not vehicle3")
		return
	
	if body == world.players_dict[owner_id] and cur_grace <= grace_frames:
		return
	
	print("HIT ", body)
	world.destroy_physical_item(item_id)
