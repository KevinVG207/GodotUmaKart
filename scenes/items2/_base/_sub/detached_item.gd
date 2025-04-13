extends PhysicalItem

class_name DetachedItem

var gravity: Vector3
@export var grace_time := 0.5
var grace_ticks: int
@export var despawn_time := 300
var despawn_ticks: int

@export var damage_type := Vehicle4.DamageType.NONE

func _ready() -> void:
	grace_ticks = floor(grace_time * Engine.physics_ticks_per_second)
	despawn_ticks = floor(despawn_time * Engine.physics_ticks_per_second)
	# TODO: GravityZone implementation
	gravity = origin.gravity

func _physics_process(_delta: float) -> void:
	grace_ticks -= 1
	despawn_ticks -= 1
	if despawn_ticks <= 0:
		destroy()
