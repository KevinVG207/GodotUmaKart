@tool
extends Node

func make_curve_between_points(p1: EnemyPath, p2: EnemyPath) -> Curve3D:
	if p1 == null or p2 == null:
		return null
	
	var curve = Curve3D.new()
	curve.add_point(p1.global_position, Vector3.ZERO, p1.global_basis.z.normalized() * p1.curve_out)
	curve.add_point(p2.global_position, Vector3.ZERO, -p2.global_basis.z.normalized() * p2.curve_in)
	
	return curve
