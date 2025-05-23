extends PathFollow3D

class_name CannonPathFollow

var vehicle: Vehicle4 = null
var speed := 50.0:
	get():
		if !gradient:
			return speed
		return gradient.sample(progress_ratio).get_luminance() * speed
var finished := false
var gradient: Gradient = null

func _ready() -> void:
	loop = false
	rotation_mode = ROTATION_ORIENTED
	tilt_enabled = true
	use_model_front = true

#func _process(_delta: float) -> void:
	#Debug.print([self, progress_ratio])

func _physics_process(delta: float) -> void:
	if finished:
		return
	
	if !vehicle:
		queue_free()
		return
	
	if !gradient:
		print("CannonPathFollow has no gradient!")
		queue_free()
		return
		
	var parent: Path3D = get_parent()

	progress += speed * delta
	
	vehicle.global_position = global_position
	vehicle.global_rotation = global_rotation
	# vehicle.transform.basis = vehicle.transform.basis.rotated(vehicle.transform.basis.y, deg_to_rad(90))
	
	vehicle.velocity.prop_vel = vehicle.transform.basis.z.normalized() * speed
	vehicle.velocity.rest_vel = Vector3.ZERO
	vehicle.prev_velocity.rest_vel = Vector3.ZERO
	vehicle.prev_velocity.prop_vel = vehicle.velocity.prop_vel
	vehicle.linear_velocity = vehicle.velocity.prop_vel
	
	if progress_ratio >= 1.0:
		finished = true
		vehicle.is_controlled = false
		vehicle.in_cannon = false
		
		#vehicle.global_position = parent.to_global(parent.curve.get_point_position(parent.curve.point_count))
		
		parent.queue_free()
		queue_free()
		return
	
	
	vehicle.is_controlled = true
	
