extends Area3D

class_name GravityZone

class GravityZoneParams:
	var direction: Vector3 = Vector3.DOWN
	var multiplier: float = 1.0
	var priority: int = 0

@export var gravity_priority: int = 0
@export var gravity_multiplier: float = 1.0
var params := GravityZoneParams.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	params.direction = -global_transform.basis.y.normalized()
	params.multiplier = gravity_multiplier
	params.priority = gravity_priority

func _on_body_entered(body: Node3D) -> void:
	if body is Vehicle4:
		body.apply_gravity_zone(self, params)

func _on_body_exited(body: Node3D) -> void:
	if body is Vehicle4:
		body.remove_gravity_zone(self)

func remove_vehicle(vehicle: Vehicle4) -> void:
	return

func add_vehicle(vehicle: Vehicle4) -> void:
	return
