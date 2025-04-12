extends Node3D

class_name PathPoint

var set_up: bool = false
@export var next_points: Array[PathPoint] = []
var prev_points: Array[PathPoint] = []

var radius: float = 4.0:
	get:
		return radius * scale.x

@export var curve_in: float = 10
@export var curve_out: float = 10

func link_points(points_array: Array[Variant]) -> void:
	if set_up:
		return
	set_up = true
	if self not in points_array:
		points_array.append(self)
	for point in next_points:
		if self not in point.prev_points:
			point.prev_points.append(self)
		point.link_points(points_array)

func get_in_vector() -> Vector3:
	return -global_transform.basis.z.normalized() * curve_in

func get_out_vector() -> Vector3:
	return global_transform.basis.z.normalized() * curve_out
