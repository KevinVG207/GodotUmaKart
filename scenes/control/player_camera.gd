extends Camera3D

class_name PlayerCam

@export var default_fov: float = 75
@export var target: Vehicle4 = null
var offset: Vector3 = Vector3(0, 2.5, -5)
var offset_finished: Vector3 = Vector3(3, 1.5, 5)
var offset_bw: Vector3 = Vector3(0, 2.5, 5)
#var offset: Vector3 = Vector3(0, 2, 5)
var look_offset: Vector3 = Vector3(0, 1.2, 0)
var look_offset_finished: Vector3 = Vector3(0, 1.2, 1)
var lerp_speed: float = 12
var lerp_speed_finished: float = 20
var lerp_speed_look: float = 30
var look_target: Array = []
@export var safe_distance: float = 1.0
#var look_target = Vector3.INF
@onready var cur_pos: Vector3 = position
@onready var cur_pos_bw: Vector3 = position
var cur_target: Vector3 = Vector3.INF

var target_gravity: Vector3 = Vector3.DOWN
var gravity_change_speed: float = 3.0

var prev_mirror: bool = false

var forwards := true
var instant := true
var finished := false
var no_move := false

var in_water := false
var water_areas := {}

var respawn_multi := 1.0
var is_respawn := false
var respawn_decel := 5.0

var cpu_duck_distance := 25.0
var duck_speed := 0.5

var cpu_volume := 1.0

func undo_respawn() -> void:
	respawn_multi = 1.0
	is_respawn = false

func do_respawn() -> void:
	respawn_multi = 1.0
	is_respawn = true

func _physics_process(delta: float) -> void:
	if !target:
		return
	
	var prev_glob_pos := global_position

	var cur_offset := offset
	var cur_offset_bw := offset_bw
	var cur_lerp_speed := lerp_speed
	var cur_look_offset := look_offset

	var target_finished := target.finished
	if target.world.spectate:
		target_finished = false
	
	if finished != target_finished:
		instant = true
		finished = target_finished
	
	if finished:
		cur_offset = offset_finished
		cur_lerp_speed = lerp_speed_finished
		cur_look_offset = look_offset_finished

	var prev_pos := cur_pos
	var prev_pos_bw := cur_pos_bw

	var new_pos := target.global_transform.translated_local(cur_offset).origin
	var new_pos_bw := target.global_transform.translated_local(cur_offset_bw).origin


	# Raycast to keep the camera from going through walls
	# Forward
	var ray_start := target.global_transform.translated_local(Vector3(0, cur_offset.y, 0)).origin
	var ray_end := new_pos
	var result := target.world.space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_start, ray_end, 1))
	if result:
		var cur_safe_distance := safe_distance
		var dist_to_point: float = result.position.distance_to(ray_start)
		if dist_to_point < safe_distance:
			cur_safe_distance = dist_to_point
		
		new_pos = result.position + (ray_start - ray_end).normalized() * cur_safe_distance
	
	# Backwards
	ray_start = target.global_transform.translated_local(Vector3(0, cur_offset_bw.y, 0)).origin
	ray_end = new_pos_bw
	result = target.world.space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_start, ray_end, 1))
	if result:
		var cur_safe_distance := safe_distance
		var dist_to_point: float = result.position.distance_to(ray_start)
		if dist_to_point < safe_distance:
			cur_safe_distance = dist_to_point
		
		new_pos_bw = result.position + (ray_start - ray_end).normalized() * cur_safe_distance

	# Slow down camera movement if respawning.
	if is_respawn:
		respawn_multi -= respawn_decel * respawn_multi * delta
	
	cur_pos = cur_pos.lerp(new_pos, cur_lerp_speed * delta * respawn_multi)
	cur_pos.y = lerpf(prev_pos.y, new_pos.y, cur_lerp_speed * delta * 0.5 * respawn_multi)
	cur_pos_bw = cur_pos_bw.lerp(new_pos_bw, cur_lerp_speed * delta * respawn_multi)
	cur_pos_bw.y = lerpf(prev_pos_bw.y, new_pos_bw.y, cur_lerp_speed * delta * 0.5 * respawn_multi)




	# # Backwards
	# ray_start = target.global_transform.translated_local(Vector3(0, cur_offset_bw.y, 0)).origin
	# ray_end = cur_pos_bw
	# result = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_start, ray_end, 1))
	# if result:
	# 	cur_pos_bw = result.position

	if instant:
		cur_pos = target.global_transform.translated_local(cur_offset).origin
		cur_pos_bw = target.global_transform.translated_local(cur_offset_bw).origin

	var mirror := false
	if target.input.mirror:
		transform.origin = cur_pos_bw
		mirror = true
	else:
		transform.origin = cur_pos
	
	var true_look_offset := target.global_transform.basis.x * cur_look_offset.x + target.global_transform.basis.y * cur_look_offset.y + target.global_transform.basis.z * cur_look_offset.z
	var true_target: Vector3 = target.global_transform.origin + true_look_offset
	if target.started:
		true_target += target.global_transform.basis.x * target.turn_speed * 0.001

	if no_move:
		global_position = prev_glob_pos

	if !is_respawn:
		target_gravity = target_gravity.slerp(target.gravity.normalized(), gravity_change_speed * delta)
		if instant:
			target_gravity = target.gravity.normalized()

	if mirror != prev_mirror or instant:
		Global.camera_switched.emit()
		look_at(true_target, -target_gravity)
	else:
		var old_basis := transform.basis
		look_at(true_target, -target_gravity)
		var new_basis := transform.basis
		transform.basis = Basis(Quaternion(old_basis).slerp(Quaternion(new_basis), lerp_speed_look * delta))

	if instant:
		instant = false

	prev_mirror = mirror


func _on_camera_area_area_entered(area: Node) -> void:
	if area is not WaterArea:
		return
	in_water = true
	water_areas[area] = true
	UI.apply_water()


func _on_camera_area_area_exited(area: Node) -> void:
	if area is not WaterArea:
		return

	water_areas.erase(area)
	if water_areas.size() == 0:
		in_water = false
		UI.clear_effect()

func _process(delta: float) -> void:
	if !target:
		return
		
	fov = default_fov + target.extra_fov
	
	handle_sound(delta)

	if Input.is_action_just_pressed("_F5"):
		var key: String = target.world.players_dict.find_key(target)
		var idx := target.world.players_dict.keys().find(key)
		idx -= 1
		idx %= target.world.players_dict.size()
		key = target.world.players_dict.keys()[idx]
		target = target.world.players_dict[key]
	if Input.is_action_just_pressed("_F6"):
		var key: String = target.world.players_dict.find_key(target)
		var idx := target.world.players_dict.keys().find(key)
		idx += 1
		idx %= target.world.players_dict.size()
		key = target.world.players_dict.keys()[idx]
		target = target.world.players_dict[key]


func handle_sound(delta: float) -> void:
	duck_cpu_engines(delta)

func duck_cpu_engines(_delta: float) -> void:
	# var bus_idx := AudioServer.get_bus_index("SFX_OTHER")
	# var old_volume := db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	
	var count := 1.0
	for vehicle: Vehicle4 in target.world.players_dict.values():
		if vehicle == target:
			continue
		var dist := global_position.distance_to(vehicle.global_position)
		if dist > cpu_duck_distance:
			continue
		#count += pow(1.0 - dist / cpu_duck_distance, 1.5)
		count += 1.0 - dist / cpu_duck_distance
	
	cpu_volume = clampf(remap(1/count, 0.0, 0.5, 0.5, 1.0), 0.0, 1.0)
		
	if Input.is_action_pressed("_F4"):
		cpu_volume = 0.0
	
	# AudioServer.set_bus_volume_db(bus_idx, linear_to_db(new_volume))
	
