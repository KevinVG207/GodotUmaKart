extends DetachedItem

@onready var handle: RigidBody3D = %Handle
var expand_speed: float = 100
var max_expand_time: float = 0.75
var max_expand_frames: int = 1
var expand_frame: int = 0
var initial_direction: Vector3
var retracting_from: Vector3
var latched_player: Vehicle4
var latch_direction: Vector3
var latched_frame: int = 0
var max_latched_frames: int = 1
var max_latched_time: float = 2.0
var detach_extra_distance: float = 1.0

@onready var springs_unit_scale: float = %Springs.scale.z

var retract_speed: float = 180
var max_retract_frames: int = 1
var retract_frame: int = 0
var uses = 3
var pull_accel: float = 3.0

enum ExpanderMode {
	EXPANDING, RETRACTING, LATCHED, USABLE
}

var mode: ExpanderMode = ExpanderMode.EXPANDING

var victim_item: PhysicalItem

func _ready() -> void:
	super()
	handle.global_position = get_owner_anchor() + owned_by.basis.z * 3.0
	initial_direction = owned_by.basis.z.normalized()
	max_expand_frames = roundi(world.PHYSICS_TICKS_PER_SECOND * max_expand_time)
	max_latched_frames = roundi(world.PHYSICS_TICKS_PER_SECOND * max_latched_time)
	victim_item = PhysicalItem.new()
	victim_item.is_active_item = true
	victim_item.speed_multi = 0.75

func _process(_delta: float) -> void:
	handle.visible = true
	%Handle2.visible = true
	if mode == ExpanderMode.USABLE:
		handle.visible = false
		%Handle2.visible = false
	#if mode == ExpanderMode.RETRACTING or mode == ExpanderMode.EXPANDING:
		#%Handle2.global_position = get_owner_anchor()
	if mode == ExpanderMode.EXPANDING:
		%Handle2.look_at(%Handle.global_position, owned_by.basis.y)
		%Handle2.global_position = get_unlatched_handle_position(owned_by, %Handle.global_position)
	if mode == ExpanderMode.RETRACTING:
		%Handle2.look_at(retracting_from, owned_by.basis.y)
		%Handle2.global_position = get_unlatched_handle_position(owned_by, retracting_from)
	if mode == ExpanderMode.LATCHED:
		%Handle2.look_at(latched_player.global_position, owned_by.basis.y)
		handle.global_position = get_latched_handle_position(latched_player, owned_by)
		%Handle2.global_position = get_latched_handle_position(owned_by, latched_player)
	%HandleVis.look_at(owned_by.global_position, owned_by.basis.y)
	%Springs.scale.z = %Handle2.global_position.distance_to(%HandleVis.global_position) * springs_unit_scale
		
func get_latched_handle_position(from: Vehicle4, to: Vehicle4) -> Vector3:
	return get_unlatched_handle_position(from, to.global_position)

func get_unlatched_handle_position(from: Vehicle4, to: Vector3) -> Vector3:
	var direction := from.global_position.direction_to(to)
	direction = Plane(from.basis.y).project(direction)
	return from.global_position + direction * from.radius

func get_owner_anchor() -> Vector3:
	return owned_by.global_position + owned_by.basis.z.normalized() * owned_by.radius

func _on_handle_integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	handle_contacts(state)
	
	if mode == ExpanderMode.RETRACTING or expand_frame >= max_expand_frames:
		if mode == ExpanderMode.EXPANDING:
			retracting_from = handle.global_position
			max_retract_frames = roundi(retracting_from.distance_to(get_owner_anchor()) / (retract_speed / world.PHYSICS_TICKS_PER_SECOND))
		expand_frame = 0
		mode = ExpanderMode.RETRACTING
	
	if mode != ExpanderMode.USABLE and retract_frame >= max_retract_frames:
		mode = ExpanderMode.USABLE
		uses -= 1
		if uses < 1:
			destroy()
		
	if latched_player:
		mode = ExpanderMode.LATCHED
		rest_vel = owned_by.global_position.direction_to(latched_player.global_position) * pull_accel
		accel_multi = 2.0
		speed_multi = 1.2
		if should_detach():
			destroy()
		if victim_item not in latched_player.active_items:
			latched_player.active_items.append(victim_item)
		latched_frame += 1
	else:
		despawn_ticks += 1
	
	match mode:
		ExpanderMode.EXPANDING:
			handle.linear_velocity = initial_direction * expand_speed
			expand_frame += 1
		ExpanderMode.RETRACTING:
			handle.linear_velocity = Vector3.ZERO
			%Col.disabled = true
			var ratio := float(retract_frame) / max_retract_frames
			handle.global_position = retracting_from + (get_unlatched_handle_position(owned_by, retracting_from) - retracting_from) * ratio
			retract_frame += 1
		ExpanderMode.LATCHED:
			%Col.disabled = true
		ExpanderMode.USABLE:
			if owned_by == world.player_vehicle and owned_by.input.item:
				mode = ExpanderMode.EXPANDING
				expand_frame = 0
				retract_frame = 0
				initial_direction = owned_by.basis.z.normalized()
				handle.global_position = get_owner_anchor()
				%Col.disabled = false

func should_detach() -> bool:
	if Plane(latch_direction, latched_player.global_position).is_point_over(owned_by.global_position):
		return true
	if owned_by.global_position.distance_to(latched_player.global_position) < owned_by.radius + latched_player.radius + detach_extra_distance:
		return true
	if latched_frame >= max_latched_frames:
		return true
	
	return false

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not body is Vehicle4:
		return
	
	var vehicle := body as Vehicle4
	if vehicle == owned_by:
		return
	
	if !latched_player:
		latched_player = vehicle
		latch_direction = owned_by.global_position.direction_to(vehicle.global_position)

func on_destroy() -> void:
	super()
	if latched_player:
		latched_player.active_items.erase(victim_item)
	return

func handle_contacts(physics_state: PhysicsDirectBodyState3D) -> void:
	for i in range(physics_state.get_contact_count()):
		var cur_ground_contact := false
		var collision_shape := Util.get_contact_collision_shape(physics_state, i)
		if collision_shape.is_in_group("col_wall"):
			expand_frame = max_expand_frames
			return
