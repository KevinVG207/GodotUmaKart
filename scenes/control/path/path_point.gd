extends BasePoint

class_name PathPoint

var radius: float = 4.0:
	get:
		return radius * scale.x

@export var curve_in: float = 10
@export var curve_out: float = 10

func get_in_vector() -> Vector3:
	return -global_transform.basis.z.normalized() * curve_in

func get_out_vector() -> Vector3:
	return global_transform.basis.z.normalized() * curve_out
