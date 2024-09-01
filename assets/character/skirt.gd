extends SoftBody3D

var pinned_points := [28, 29, 30, 31, 32, 0, 1, 2, 3, 4, 5, 6, 7]
var pinned_points2 := [19, 20, 21, 22, 23, 24, 25, 41, 42, 43, 44, 45]
@export var transform_parent: Node3D
@export var more_pins := true

func _ready():
	var parent_path: String = transform_parent.get_path()
	for point in pinned_points:
		set_point_pinned(point, true, parent_path)
	
	if more_pins:
		for point in pinned_points2:
			set_point_pinned(point, true, parent_path)
