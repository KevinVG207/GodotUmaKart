extends Area3D

class_name CannonTrigger

@export var speed: float = 50.0
@export var gradient: GradientTexture1D

func _on_body_entered(body: Node3D) -> void:
	if body is not Vehicle3:
		return
	
	var vehicle: Vehicle3 = body
	if vehicle.respawn_stage:
		return
	
	vehicle.is_being_controlled = true
	vehicle.in_cannon = true
	
	var new_path := make_new_path(vehicle)
	var new_follow := CannonPathFollow.new()
	new_follow.vehicle = vehicle
	new_follow.speed = speed
	new_follow.gradient = gradient.gradient
	new_path.add_child(new_follow)
	
	var seconds := new_path.curve.get_baked_length() / speed
	

func make_new_path(vehicle: Vehicle3) -> Path3D:
	var new_path := Path3D.new()
	add_child(new_path)
	var new_curve := Curve3D.new()
	
	var old_curve: Curve3D = %Path.curve
	
	#for i in range(old_curve.point_count):
		#new_curve.add_point(
			#old_curve.get_point_position(i),
			#old_curve.get_point_in(i),
			#old_curve.get_point_out(i))
		#new_curve.set_point_tilt(i, old_curve.get_point_tilt(i))
	
	new_path.curve = old_curve
	
	new_path.global_position = %Path.global_position
	new_path.global_rotation = %Path.global_rotation

	var delta_pos: Vector3 = vehicle.global_position - %Path.global_position
	new_path.global_position += delta_pos

	return new_path
