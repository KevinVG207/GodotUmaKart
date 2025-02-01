extends GravityZone

class_name SphericalGravityZone

var vehicles: Dictionary = {}

func _ready() -> void:
	return

func _physics_process(_delta: float) -> void:
	for vehicle: Vehicle4 in vehicles.keys():
		var new_params = GravityZoneParams.new()
		new_params.multiplier = params.multiplier
		new_params.priority = params.priority
		new_params.direction = (global_position - vehicle.global_position).normalized()
		vehicle.apply_gravity_zone(self, new_params)

func _on_body_entered(body: Node3D) -> void:
	if body is Vehicle4:
		vehicles[body] = null

func _on_body_exited(body: Node3D) -> void:
	if body is Vehicle4:
		body.remove_gravity_zone(self)
		vehicles.erase(body)
