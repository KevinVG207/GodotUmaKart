@tool
extends Node

func make_curve_between_pathpoints(p1: PathPoint, p2: PathPoint) -> Curve3D:
	if p1 == null or p2 == null:
		return null
	
	return make_curve(
		p1.global_position,
		p2.global_position,
		p1.global_basis.z.normalized() * p1.curve_out,
		-p2.global_basis.z.normalized() * p2.curve_in
	)

func make_curve(p1: Vector3, p2: Vector3, out_vec: Vector3, in_vec: Vector3, bake_interval:float=1.0) -> Curve3D:
	var curve = Curve3D.new()
	curve.bake_interval = bake_interval
	curve.add_point(p1, Vector3.ZERO, out_vec)
	curve.add_point(p2, in_vec, Vector3.ZERO)
	return curve
