extends TriggerBasedGravityZone

@onready var path: Path3D = %Path3D
@onready var curve: Curve3D = %Path3D.curve
@export var fall_distance: float = 25.0

func _physics_process(_delta: float) -> void:
	for vehicle: Vehicle4 in vehicles.keys():
		var new_params = vehicles[vehicle]
		new_params.multiplier = gravity_multiplier
		new_params.priority = gravity_priority
		
		var local_pos := path.to_local(vehicle.global_position)
		var closest_point := path.to_global(curve.sample_baked(curve.get_closest_offset(local_pos)))
		var diff := closest_point - vehicle.global_position
		
		if Util.v3_length_compare(diff, fall_distance) > 0:
		# if diff.length() > fall_distance:
			vehicle.respawn()
		
		new_params.direction = diff.normalized()
		
		vehicle.apply_gravity_zone(self, new_params)
