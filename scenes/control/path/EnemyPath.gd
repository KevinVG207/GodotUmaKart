extends Node3D

class_name EnemyPath

var dist: float = 6.0:
	get:
		return dist * scale.x
var next_points: Array = []
