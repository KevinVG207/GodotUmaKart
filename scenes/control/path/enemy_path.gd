extends PathPoint

class_name EnemyPath

var dist: float = 6.0:
	get:
		return dist * scale.x

var normal: Vector3 = Vector3.FORWARD
