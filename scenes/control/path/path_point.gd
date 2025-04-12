extends Node3D

class_name PathPoint

var set_up: bool = false
@export var next_points: Array[PathPoint] = []
var prev_points: Array[PathPoint] = []

var radius: float = 6.0:
	get:
		return radius * scale.x

@export var curve_out: float = 3
@export var curve_in: float = 3

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
