extends Area3D

var item_id: String
var owner_id: String
var world: RaceBase

func _physics_process(_delta):
	var vehicle = world.players_dict[owner_id] as Vehicle3
	
	if vehicle.is_player and !vehicle.input_item:
		# User let go of the item! Turn into thrown shell.
		world.destroy_physical_item(item_id)
		world.make_physical_item("thrown_green_shell", world.players_dict[owner_id])
		return
	
	var ray_start = vehicle.prev_transform.origin + (-vehicle.prev_transform.basis.x * (vehicle.vehicle_length_behind + 0.5))
	ray_start += vehicle.prev_transform.basis.y * 0.5
	var ray_end = ray_start + -vehicle.prev_transform.basis.y * (0.5 + vehicle.vehicle_height_below + 0.1)
	var ray_hit = Util.raycast_for_group(self, ray_start, ray_end, "floor", [self])
	var new_pos = ray_end
	if ray_hit:
		new_pos = ray_hit["position"]
	global_position = new_pos
	transform.basis = vehicle.prev_transform.basis

func get_state() -> Dictionary:
	return {}
	
func set_state(state: Dictionary):
	return
