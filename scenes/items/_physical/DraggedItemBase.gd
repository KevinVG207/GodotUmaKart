extends Area3D

var physical_item := true
var item_id: String
var owner_id: String
var world: RaceBase
var no_updates: bool = false

@export var next_item_key: String
@export var damage_type: Vehicle4.DamageType

func _enter_tree() -> void:
	update_position()

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	var vehicle := world.players_dict[owner_id] as Vehicle4

	if item_id in world.deleted_physical_items:
		self.queue_free()
		return
	
	vehicle.has_dragged_item = true
	
	if !vehicle.input.item and not vehicle.is_network:
		# User let go of the item! Turn into thrown item.
		world.destroy_physical_item(item_id)
		world.make_physical_item(next_item_key, world.players_dict[owner_id])
		return
	
	update_position()


func get_state() -> Dictionary:
	return {}
	
func set_state(state: Dictionary) -> void:
	return

func update_position() -> void:
	var vehicle := world.players_dict[owner_id] as Vehicle4
	var ray_start: Vector3 = vehicle.prev_transform.origin + (-vehicle.prev_transform.basis.z * (vehicle.vehicle_length_behind + 0.5))
	ray_start += vehicle.prev_transform.basis.y * 0.5
	var ray_end := ray_start + -vehicle.prev_transform.basis.y * (0.5 + vehicle.vehicle_height_below + 0.1)
	var ray_hit := Util.raycast_for_group(world.space_state, ray_start, ray_end, "col_floor", [self])
	var new_pos := ray_end
	if ray_hit:
		new_pos = ray_hit["position"]
	global_position = new_pos
	transform.basis = vehicle.prev_transform.basis


func _on_body_entered(body: Node) -> void:
	if body == self:
		return
	if "physical_item" in body:
		world.destroy_physical_item(item_id)
		world.destroy_physical_item(body.item_id)
		return
	
	if body is Vehicle4 and body.user_id != owner_id and damage_type and !body.is_network:
		body.damage(damage_type)
		world.destroy_physical_item(item_id)

func _exit_tree() -> void:
	world.players_dict[owner_id].has_dragged_item = false
