extends GravityZone

class_name SphericalGravityZone

var vehicles: Dictionary = {}

func _ready() -> void:
	return

func _physics_process(_delta: float) -> void:
	for vehicle: Vehicle4 in vehicles.keys():
		var new_params = vehicles[vehicle]
		new_params.multiplier = params.multiplier
		new_params.priority = params.priority
		new_params.direction = (global_position - vehicle.global_position).normalized()
		vehicle.apply_gravity_zone(self, new_params)

func _on_body_entered(body: Node3D) -> void:
	if body is Vehicle4:
		add_vehicle(body)

func _on_body_exited(body: Node3D) -> void:
	if body is Vehicle4:
		body.remove_gravity_zone(self)
		vehicles.erase(body)

func remove_vehicle(vehicle: Vehicle4) -> void:
	vehicle.remove_gravity_zone(self)
	vehicles.erase(vehicle)

func add_vehicle(vehicle: Vehicle4) -> void:
	vehicles[vehicle] = GravityZoneParams.new()
