extends Node3D

class_name TriggerBasedGravityZone

var vehicles: Dictionary = {}

@export var gravity_priority: int = 0
@export var gravity_multiplier: float = 1.0

func _physics_process(_delta: float) -> void:
	for vehicle: Vehicle4 in vehicles.keys():
		var new_params = vehicles[vehicle]
		new_params.multiplier = gravity_multiplier
		new_params.priority = gravity_priority
		new_params.direction = -global_transform.basis.y.normalized()
		vehicle.apply_gravity_zone(self, new_params)

func _on_body_start_entered(body: Node3D) -> void:
	if body is Vehicle4:
		add_vehicle(body)

func _on_body_exit_entered(body: Node3D) -> void:
	if body is Vehicle4:
		body.remove_gravity_zone(self)
		vehicles.erase(body)

func remove_vehicle(vehicle: Vehicle4) -> void:
	vehicle.remove_gravity_zone(self)
	vehicles.erase(vehicle)

func add_vehicle(vehicle: Vehicle4) -> void:
	vehicles[vehicle] = GravityZone.GravityZoneParams.new()
