extends Area3D

var physical_item = true
var item_id: String
var owner_id: String
var world: RaceBase
var no_updates: bool = false

@export var next_item_key: String
@export var damage_type: int

func _enter_tree():
	update_position()

func _ready():
	self.body_entered.connect(_on_body_entered)

func _physics_process(_delta):
	if item_id in world.deleted_physical_items:
		self.queue_free()
		return
	
	var vehicle = world.players_dict[owner_id] as Vehicle3
	
	if !vehicle.input_item and not vehicle.is_network:
		# User let go of the item! Turn into thrown item.
		world.destroy_physical_item(item_id)
		world.make_physical_item(next_item_key, world.players_dict[owner_id])
		return
	
	update_position()


func get_state() -> Dictionary:
	return {}
	
func set_state(state: Dictionary):
	return

func update_position():
	var vehicle = world.players_dict[owner_id] as Vehicle3
	var ray_start = vehicle.prev_transform.origin + (-vehicle.prev_transform.basis.x * (vehicle.vehicle_length_behind + 0.5))
	ray_start += vehicle.prev_transform.basis.y * 0.5
	var ray_end = ray_start + -vehicle.prev_transform.basis.y * (0.5 + vehicle.vehicle_height_below + 0.1)
	var ray_hit = Util.raycast_for_group(world.space_state, ray_start, ray_end, "floor", [self])
	var new_pos = ray_end
	if ray_hit:
		new_pos = ray_hit["position"]
	global_position = new_pos
	transform.basis = vehicle.prev_transform.basis


func _on_body_entered(body):
	if body == self:
		return
	if "physical_item" in body:
		world.destroy_physical_item(item_id)
		world.destroy_physical_item(body.item_id)
		return
	
	if body is Vehicle3 and body.user_id != owner_id and damage_type and !body.is_network:
		body.damage(damage_type)
		world.destroy_physical_item(item_id)
