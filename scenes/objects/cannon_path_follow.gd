extends PathFollow3D

class_name CannonPathFollow

var vehicle: Vehicle3 = null
var speed := 50.0
var finished := false

func _ready() -> void:
	loop = false
	rotation_mode = ROTATION_ORIENTED
	tilt_enabled = true
	#use_model_front = true

#func _process(_delta: float) -> void:
	#Debug.print([self, progress_ratio])

func _physics_process(delta: float) -> void:
	if finished:
		return
	
	if !vehicle:
		queue_free()
		return
		
	var parent: Path3D = get_parent()

	progress += speed * delta
	
	vehicle.global_position = global_position
	vehicle.global_rotation = global_rotation
	vehicle.transform.basis = vehicle.transform.basis.rotated(vehicle.transform.basis.y, deg_to_rad(90))
	
	vehicle.prop_vel = vehicle.transform.basis.x.normalized() * speed
	vehicle.rest_vel = Vector3.ZERO
	vehicle.prev_rest_vel = Vector3.ZERO
	vehicle.prev_prop_vel = vehicle.prop_vel
	vehicle.prev_vel = Vector3.ZERO
	vehicle.linear_velocity = vehicle.prop_vel
	
	if progress_ratio >= 1.0:
		finished = true
		vehicle.is_being_controlled = false
		vehicle.in_cannon = false
		
		#vehicle.global_position = parent.to_global(parent.curve.get_point_position(parent.curve.point_count))
		
		parent.queue_free()
		queue_free()
		return
	
	
	vehicle.is_being_controlled = true
	
