extends Node3D

# We assume the wheel model has a radius of 1m

@onready var parent: Vehicle4 = get_parent().get_parent().get_parent()
@onready var radius := scale.x
var anchor := Vector3.ZERO
@onready var initial_rotation := rotation_degrees

@export var steer := false
var cur_steer_deg := 0.0
var steer_multi := 300.0
var cur_rot := 0.0

func _ready() -> void:
	anchor = position

func _process(delta: float) -> void:
	# Roll over the ground.
	var new_rot := initial_rotation
	
	var dist_travelled := parent.cur_speed * delta
	var circum := 2.0 * PI * radius
	var degrees := 360 * (dist_travelled/circum)
	
	cur_rot += degrees
	cur_rot = fmod(cur_rot, 360)
	
	new_rot.x -= cur_rot
	# Do a raycast in the direction of the parent down.
	var parent_up := parent.transform.basis.y
	
	var start_pos: Vector3 = parent.to_global(anchor) + (-parent_up * radius * 0.75)
	var end_pos: Vector3 = parent.to_global(anchor) + (-parent_up * radius * 1.25)
	
	#var local_pos = parent.to_local(end_pos)
	#local_pos.y += radius
	#position = local_pos
	
	var param := PhysicsRayQueryParameters3D.create(start_pos, end_pos, 1, [self])
	var result := parent.world.space_state.intersect_ray(param)
	var point := end_pos
	if result:
		point = result.position
	
	point = parent.to_local(point)
	point.y += radius
	
	# TODO: This does not work with other gravities than down!5
	#if point.y < position.y:
		#position.y = move_toward(position.y, point.y, abs(delta * parent.gravity.y * 0.05))
	#else:
		#position.y = point.y
	position.y = move_toward(position.y, point.y, abs(delta * parent.gravity.y * 0.03))

	if steer:
		var target_rot : float = parent.turn_speed * 0.3
		if parent.cur_speed < -0.1:
			target_rot *= -1.0
		cur_steer_deg = move_toward(cur_steer_deg, target_rot, delta * steer_multi)
		new_rot.y += cur_steer_deg
	
	rotation_degrees = new_rot
