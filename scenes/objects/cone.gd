extends StageObject

@onready var DESPAWN_TICKS := world.PHYSICS_TICKS_PER_SECOND * 6
var cur_despawn_ticks := -1
@onready var initial_scale: Vector3 = %Rigidbody.scale

func _physics_process(_delta: float) -> void:
	cur_despawn_ticks -= 1
	if cur_despawn_ticks == world.PHYSICS_TICKS_PER_SECOND:
		start_animation()
	if cur_despawn_ticks == 0:
		respawn()
	if cur_despawn_ticks <= -1:
		cur_despawn_ticks = -1

func start_animation() -> void:
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(%Rigidbody, "scale", Vector3(0.01, 0.01, 0.01), 0.95).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)

func respawn() -> void:
	%Rigidbody.global_transform = global_transform
	%Rigidbody.scale = initial_scale
	%Rigidbody.linear_velocity = Vector3.ZERO
	%Rigidbody.angular_velocity = Vector3.ZERO

func _on_rigidbody_body_entered(body: Node) -> void:
	if body is not StaticBody3D:
		cur_despawn_ticks = DESPAWN_TICKS
