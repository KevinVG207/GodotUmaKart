extends PhysicalItem

class_name DraggedItem

@export var area: Area3D
@export var damage_type: Vehicle4.DamageType
@export var next_item_key: String

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	var vehicle := world.players_dict[owner_id] as Vehicle4

	if key in world.deleted_physical_items:
		self.queue_free()
		return
	
	vehicle.has_dragged_item = true
	
	if !vehicle.input.item and not vehicle.is_network:
		# User let go of the item! Turn into thrown item.
		destroy()
		
		if next_item_key:
			world.make_physical_item(next_item_key, owned_by)
		return
	
	update_position()

func update_position() -> void:
	var ray_start: Vector3 = owned_by.prev_transform.origin + (-owned_by.prev_transform.basis.z * (owned_by.vehicle_length_behind + 0.5))
	ray_start += owned_by.prev_transform.basis.y * 0.5
	var ray_end := ray_start + -owned_by.prev_transform.basis.y * (0.5 + owned_by.vehicle_height_below + 0.1)
	var ray_hit := Util.raycast_for_group(world.space_state, ray_start, ray_end, "col_floor", [self])
	var new_pos := ray_end
	if ray_hit:
		new_pos = ray_hit["position"]
	area.global_position = new_pos
	area.transform.basis = owned_by.prev_transform.basis

func _on_body_entered(body: Variant) -> void:
	if body == self:
		return
	if body is PhysicalItem:
		destroy()
		body.destroy()
		return
	
	if body is Vehicle4:
		var vehicle := body as Vehicle4
		if damage_type != Vehicle4.DamageType.NONE and vehicle != owned_by and !vehicle.network:
			vehicle.damage(damage_type)
			destroy()
		return

func _exit_tree() -> void:
	world.players_dict[owner_id].has_dragged_item = false
