extends Node3D

class_name BasePoint

var set_up: bool = false
@export var next_points: Array[BasePoint] = []
var prev_points: Array[BasePoint] = []

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

func link_next_prev() -> void:
	for point in next_points:
		if self in point.prev_points:
			continue
		point.prev_points.append(self)
