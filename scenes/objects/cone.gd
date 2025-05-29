extends StageObject

@onready var DESPAWN_TICKS := world.PHYSICS_TICKS_PER_SECOND * 6
var cur_despawn_ticks := -1
@onready var initial_scale: Vector3 = %Rigidbody.scale
var is_respawning := false

func _physics_process(delta: float) -> void:
	%Rigidbody.linear_velocity += world.base_gravity * delta
	
	cur_despawn_ticks -= 1
	if cur_despawn_ticks == world.PHYSICS_TICKS_PER_SECOND:
		is_respawning = true
		start_animation()
	if cur_despawn_ticks == 0:
		is_respawning = false
		respawn()
	if cur_despawn_ticks <= -1:
		cur_despawn_ticks = -1
		
		if !is_respawning and global_position.distance_squared_to(%Rigidbody.global_position) > 25.0:
			print("DESPAWNING FROM DISTANCE ", name)
			cur_despawn_ticks = DESPAWN_TICKS

func start_animation() -> void:
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(%Rigidbody, "scale", Vector3(0.01, 0.01, 0.01), 0.95).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)

func respawn() -> void:
	%Rigidbody.global_transform = global_transform
	%Rigidbody.scale = initial_scale
	%Rigidbody.linear_velocity = Vector3.ZERO
	%Rigidbody.angular_velocity = Vector3.ZERO

func _on_rigidbody_body_entered(body: Node) -> void:
	print(world.time)
	if world.time > 0:
		%Impact.pitch_scale = randf_range(1.2, 1.6)
		%Impact.play()
	if body is not StaticBody3D:
		cur_despawn_ticks = DESPAWN_TICKS
