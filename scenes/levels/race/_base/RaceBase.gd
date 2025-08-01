extends Node3D

class_name RaceBase

@onready var player_camera: PlayerCam = $PlayerCamera
@onready var intro_camera: Camera3D = %IntroCamera
var updates_to_server_per_second: int = 6
var checkpoints: Array = []
var key_checkpoints: Dictionary = {}
var players_dict: Dictionary[int, Vehicle4] = {}
var removed_players_dict: Dictionary[int, Vehicle4] = {}
var frames_between_update: int = 60
var update_wait_frames: int = 0
var should_exit: bool = false
var update_thread: Thread
var player_vehicle: Vehicle4 = null
var player_user_id: int = 0
var removed_player_ids: Array = []
var starting_order: Array = []
var spectate: bool = false
# var timer_tick: int = 0
var time := 0.0
var tick := 0
var race_start_time: float = 0
var physical_items: Dictionary[String, PhysicalItem] = {}
var deleted_physical_items: Array[String] = []
var all_enemy_points: Array[EnemyPath] = []
var network_path_points: Dictionary = {}
@onready var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

@export var start_offset_z: float = 2
@export var start_offset_x: float = 3

@onready var vehicles_node: Node3D = $Vehicles

# var player_scene: PackedScene = preload("res://scenes/vehicles/vehicle_4.tscn")
var player_scene: PackedScene = preload("res://scenes/vehicles/list/kart_outside.tscn")
var rank_panel_scene: PackedScene = preload("res://scenes/ui/rank_panel.tscn")

var menu_cam_str: String = "%CamFountain"
var menu_scene: String = "res://scenes/ui/academy/menu_academy.tscn"
var lobby_cam_str: String = "%CamTrunk"
var lobby_scene: String = "res://scenes/ui/academy/menu_academy.tscn"

@export var lap_count: int = 3
var finished := false

@export var base_gravity := Vector3(0, -18, 0)

var path_point_scene: PackedScene = preload("res://scenes/control/path/EnemyPath.tscn")

var finish_order: Array = []
var rankings_timer: int = 0
var rankings_delay: int = 1
var stop_rankings: bool = false

var debug_window: Window = null
var debug_cam: Camera3D = null

var pings: Dictionary

var pause_cooldown: int = 0
var pause_start: int = -1

var course_length: float = 1.0

var cpu_avg_speed: float = 22.5

var course_name: String = "default"

var countdown_timer: int = 0
var countdown_state: int = 3
var countdown_gap: float = 1.5
var countdown_seconds_total := (countdown_state-1) * countdown_gap

var map_outline_color: Color = Color(0.37, 0.37, 0.37, 1.0)
@export var map_outline_width: float = 2.5
@export var map_mesh_instances: Array[NodePath] = []
var map_mesh_material: ShaderMaterial = preload("res://scenes/levels/race/_base/MapMaterial.tres")

@export var fall_failsafe: float = -100

@export var start_enemy_points: Array[EnemyPath] = []

@export_category("Music")
@export var music_volume_multi: float = 1.0
@export var final_lap_speed_multi: float = 1.2
@export var music: AudioStreamSynchronized

const PHYSICS_TICKS_PER_SECOND: int = 60

class raceOp:
	const SERVER_UPDATE_VEHICLE_STATE = 1
	const CLIENT_UPDATE_VEHICLE_STATE = 2
	const SERVER_PING = 3
	const CLIENT_VOTE = 4
	const SERVER_PING_DATA = 5
	const SERVER_RACE_START = 6
	const CLIENT_READY = 7
	const SERVER_RACE_OVER = 8
	const SERVER_CLIENT_DISCONNECT = 9
	const SERVER_ABORT = 10
	const CLIENT_SPAWN_ITEM = 11
	const CLIENT_DESTROY_ITEM = 12
	const SERVER_SPAWN_ITEM = 13
	const SERVER_DESTROY_ITEM = 14
	const CLIENT_ITEM_STATE = 15
	const SERVER_ITEM_STATE = 16
	const SERVER_PING_UPDATE = 17

class finishType:
	const NORMAL = 0
	const TIMEOUT = 1

const STATE_DISCONNECT = -1
const STATE_INITIAL = 0
const STATE_JOINING = 1
const STATE_CAN_READY = 2
const STATE_READY_FOR_START = 3
const STATE_WAIT_FOR_START = 4
const STATE_COURSE_INTRO = 5
const STATE_DRIVER_INTRO = 6
const STATE_COUNTDOWN = 7
const STATE_COUNTING_DOWN = 8
const STATE_RACE = 9
const STATE_RACE_OVER = 10
const STATE_READY_FOR_RANKINGS = 11
const STATE_SHOW_RANKINGS = 12
const STATE_JOIN_NEXT = 13
const STATE_JOINING_NEXT = 14
const STATE_SPECTATING = 15

const UPDATE_STATES = [
	STATE_COUNTDOWN,
	STATE_COUNTING_DOWN,
	STATE_RACE,
	STATE_RACE_OVER,
	STATE_READY_FOR_RANKINGS,
	STATE_SHOW_RANKINGS,
	STATE_JOIN_NEXT
]

const REPLAY_STATES = [
	STATE_COUNTING_DOWN,
	STATE_RACE,
	STATE_RACE_OVER,
	STATE_READY_FOR_RANKINGS,
	STATE_SHOW_RANKINGS
]

var state: int = STATE_INITIAL

@onready var map_camera: Camera3D = $MapCamera

@onready var replay_manager: ReplayManager = %ReplayManager
@onready var replay_vehicles: Node3D = $ReplayVehicles

var loaded_replay: Array = []
var loaded_replay_idx: int = 0
var loaded_replay_vehicle: Vehicle4 = null

var network_room: DomainRoom.Race

var course_intro_tween: Tween = null

func _ready() -> void:
	course_name = Util.get_race_course_name_from_path(scene_file_path)
	
	# Setup ticks
	Engine.physics_ticks_per_second = PHYSICS_TICKS_PER_SECOND
	frames_between_update = int(float(Engine.physics_ticks_per_second) / updates_to_server_per_second)
	
	countdown_timer = PHYSICS_TICKS_PER_SECOND * countdown_gap * countdown_seconds_total
	
	rankings_delay = PHYSICS_TICKS_PER_SECOND / 6
	
	UI.race_ui.set_max_laps(lap_count)
	UI.race_ui.set_cur_lap(0)
	
	UI.race_ui.back_btn.pressed.connect(_on_back_pressed)

	checkpoints = []
	key_checkpoints = {}
	
	# Setup checkpoints
	for checkpoint: Checkpoint in $Checkpoints.get_children():
		checkpoints.append(checkpoint)
		if checkpoint.is_key:
			key_checkpoints[checkpoint] = key_checkpoints.size()
	set_course_length()  # This also sets up checkpoint lengths.
	
	setup_enemy_path()

	setup_map_meshes()
	
	setup_course_default_collision_type()
	
	#minimap_recursive($Course)
	# $Course/MapMesh.visible = true
	UI.race_ui.set_map_camera(map_camera)
	UI.race_ui.set_startline(checkpoints[0])

	if Global.selected_replay:
		replay_manager.load_replay(Global.selected_replay, self)
		Global.selected_replay = ""

func setup_map_meshes() -> void:
	for path: NodePath in map_mesh_instances:
		var mesh: MeshInstance3D = get_node(path)
		mesh.layers = 0
		mesh.set_layer_mask_value(19, true)
		mesh.visible = true
		map_mesh_material.set_shader_parameter("color", map_outline_color)
		map_mesh_material.set_shader_parameter("outline_thickness", map_outline_width)
		mesh.material_override = map_mesh_material

func setup_course_default_collision_type() -> void:
	recursive_set_floor(%Course)

func recursive_set_floor(node: Node) -> void:
	for child: Node in node.get_children():
		recursive_set_floor(child)
	
	if not node is CollisionShape3D:
		return
	
	if node.get_groups().is_empty():
		node.add_to_group("col_floor")
		return
	
	var wall := false
	for group in node.get_groups():
		if group == "col_wall":
			wall = true
			break
	
	if not wall:
		node.add_to_group("col_floor")
	
	return


func setup_enemy_path() -> void:
	for point in start_enemy_points:
		point.link_points(all_enemy_points)
	
	# Set up prev_points
	# TODO: Remove this
	for point in all_enemy_points:
		var normals: PackedVector3Array = []
		for next_point in point.next_points:
			normals.append((next_point.global_position - point.global_position).normalized())
		
		var avg_normal: Vector3 = Util.sum(normals) / normals.size()
		point.normal = avg_normal.normalized()

func pick_next_point_to_target(cur_point: EnemyPath, target_point: EnemyPath) -> EnemyPath:
	var cur_leaves: Array = target_point.prev_points
	
	while true:
		cur_leaves.shuffle()
		var new_leaves: Array = []
		for i in len(cur_leaves):
			var leaf: EnemyPath = cur_leaves[i]
			if cur_point in leaf.prev_points:
				return leaf
			new_leaves += leaf.prev_points
		cur_leaves = new_leaves
	
	print("PANIC: Could not pick next point to target!")
	return cur_point


func pick_next_path_point(cur_point: EnemyPath, _use_boost: bool=false) -> EnemyPath:
	var next_points := cur_point.next_points
	if next_points.is_empty():
		return cur_point
	var next_point := next_points.pick_random() as EnemyPath
	return next_point
	
#func find_closest_enemy_point(player: Vehicle4) -> EnemyPath:
	#var closest_pt: EnemyPath = all_enemy_points[0]
	#var closest_dist: float = closest_pt.global_position.distance_to(player.global_position)
	#for point: EnemyPath in all_enemy_points.slice(1):
		#var dist: float = point.global_position.distance_to(player.global_position)
		#if dist < closest_dist:
			#closest_dist = dist
			#closest_pt = point
	#return closest_pt

func get_timer_seconds() -> float:
	if race_start_time == 0:
		return 0.0
	return (Time.get_ticks_usec() - race_start_time) / 1000000.0

func _process(delta: float) -> void:
	if state == STATE_JOINING_NEXT:
		return
	
	# TODO: Check if this is truly accurate!
	# Adjust timer after pausing
	if pause_start != -1:
		var pause_delta: int = Time.get_ticks_usec() - pause_start
		race_start_time += pause_delta
		pause_start = -1
	
	if state == STATE_RACE and Global.MODE1 == Global.MODE1_OFFLINE and Input.is_action_just_pressed("_pause") and pause_cooldown <= 0:
		# Start pause
		pause_cooldown = round(Engine.physics_ticks_per_second / 4.0)
		get_tree().paused = true
		UI.race_ui.pause_menu.enable()
		pause_start = Time.get_ticks_usec() + (delta * 1000000.0)
		return
	
	update_ranks()
	
	UI.race_ui.set_startline(checkpoints[0])
		
	if state == STATE_COUNTING_DOWN:
		#advance_replay()
		pass
	
	if state == STATE_RACE:
		UI.race_ui.update_time(get_timer_seconds())
		#advance_replay()
	
	if state == STATE_SHOW_RANKINGS:
		UI.race_ui.show_back_btn()
		if !%NextRaceTimer.is_stopped():
			UI.race_ui.update_timeleft(%NextRaceTimer.time_left)
	
	if spectate and players_dict:
		if !player_camera.target and players_dict:
			player_camera.target = players_dict.values()[0]
			player_camera.instant = true
		
		var spectator_index = players_dict.values().find(player_camera.target)
		if spectator_index > -1:
			UI.race_ui.enable_spectating()
			#UI.race_ui.set_username(players_dict[players_dict.keys()[spectator_index]].username)
			
			if get_window().has_focus() and Input.is_action_just_pressed("accelerate"):
				player_camera.instant = true
				spectator_index += 1
				if spectator_index >= players_dict.size():
					spectator_index = 0
			elif get_window().has_focus() and Input.is_action_just_pressed("brake"):
				player_camera.instant = true
				spectator_index -= 1
				if spectator_index < 0:
					spectator_index = players_dict.size()-1
			
			player_camera.target = players_dict.values()[spectator_index]
	
	if player_camera.target and player_camera.target.finished:
		UI.race_ui.update_time(player_camera.target.finish_time)
	
	# Minimap iconsr
	UI.race_ui.update_icons(players_dict.values())
	
	# Nametags
	if player_camera.target:
		# Display nametags.
		var exclude_list: Array = []
		for vehicle: Vehicle4 in players_dict.values():
			exclude_list.append(vehicle.get_rid())
			
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		var nt_deadzone_sides := viewport_size.x / 10
		var nt_deadzone_top := viewport_size.y / 14
		var nt_deadzone_bottom := viewport_size.y / 3
		
		for user_id: int in players_dict.keys():
			var vehicle := players_dict[user_id] as Vehicle4
			if vehicle == player_vehicle:
				continue
			var nametag_pos := vehicle.transform.origin + (player_camera.transform.basis.y * 1.5) as Vector3
			#var second_check = nametag_pos + (player_camera.transform.basis.z * -5.0)
			var dist := nametag_pos.distance_to(player_camera.global_position)
			var tag_visible := true
			var force := false
			#if dist > 75 or player_camera.is_position_behind(second_check):
			if dist > 75:
				tag_visible = false
			
			if not player_camera.is_position_in_frustum(nametag_pos):
				tag_visible = false
				force = true
			
			# Raycast between camera pos and nametag_pos. If anything is in-between, don't render the nametag.
			if tag_visible:
				var ray_result := space_state.intersect_ray(PhysicsRayQueryParameters3D.create(player_camera.global_position, nametag_pos, 0xFFFFFFFF, exclude_list))
				if ray_result:
					tag_visible = false
			
			var screen_pos := player_camera.unproject_position(nametag_pos)

			if screen_pos.x < nt_deadzone_sides or screen_pos.x > viewport_size.x - nt_deadzone_sides or screen_pos.y < nt_deadzone_top or screen_pos.y > viewport_size.y - nt_deadzone_bottom:
				tag_visible = false
				
			var opacity := 1.0
			if dist > 60:
				opacity = remap(dist, 60, 75, 1.0, 0.0)
			
			#if state == STATE_RACE_OVER or state in UPDATE_STATES and player_vehicle.finished:
			if (state != STATE_RACE and state != STATE_SPECTATING) or get_timer_seconds() < 2.0:
				tag_visible = false
			
			UI.race_ui.update_nametag(user_id, vehicle.username, screen_pos, opacity, dist, tag_visible, force, delta)
		UI.race_ui.sort_nametags()
	
	# Debug window
	if Input.is_action_just_pressed("_F12"):
		if debug_window:
			ProjectSettings.set_setting("display/window/subwindows/embed_subwindows", true)
			debug_window.queue_free()
			debug_cam.queue_free()
			debug_window = null
			debug_cam = null
		else:
			ProjectSettings.set_setting("display/window/subwindows/embed_subwindows", false)
			debug_window = Window.new()
			debug_window.size = Vector2(1280,720)
			debug_cam = PlayerCam.new()
			add_child(debug_window)
			add_child(debug_cam)
			RenderingServer.viewport_attach_camera(debug_window.get_viewport_rid(), debug_cam.get_camera_rid())
			debug_cam.cull_mask = player_camera.cull_mask
			debug_cam.global_position = player_camera.global_position
			debug_cam.target = player_camera.target
			debug_cam.no_move = true

func minimap_recursive(node: Node):
	for child in node.get_children():
		minimap_recursive(child)
	
	# Add floor meshes to minimap layer
	if node is MeshInstance3D:
		if node.is_in_group("map"):
			node.set_layer_mask_value(19, true)  # Minimap layer

func change_state(new_state: int, state_func: Callable = Callable()):
	state = new_state
	state_func.call()

func make_physical_item(key: String, player: Vehicle4) -> PhysicalItem:
	if player.is_network:
		return

	var unique_key := Util.uuid.v4()
	var instance := Global.physical_items[key].instantiate()
	instance.setup(unique_key, self, player)
	physical_items[unique_key] = instance
	$Items.add_child(instance)
	
	if state == STATE_INITIAL:
		return instance
	
	var dto := DomainRace.ItemSpawnWrapper.new()
	dto.key = unique_key
	dto.type = key
	dto.owner_id = instance.owner_id
	dto.origin_id = instance.origin_id
	dto.state = instance.get_state()

	if Global.MODE1 == Global.MODE1_ONLINE:
		RPCServer.race_spawn_item.rpc_id(1, dto.serialize())
	
	replay_manager.spawn_item(dto)

	return instance


func spawn_physical_item(data: DomainRace.ItemSpawnWrapper):
	if data.key in deleted_physical_items:
		return
	
	# Ignore already owned items
	if data.owner_id == player_user_id:
		return
	
	if data.key in physical_items.keys():
		return
	
	var instance = Global.physical_items[data.type].instantiate() as PhysicalItem
	instance.setup(data.key, self, players_dict[data.origin_id])
	instance.owner_id = data.owner_id
	physical_items[data.key] = instance
	$Items.add_child(instance)
	instance.set_state(data.state)
	
	replay_manager.spawn_item(data)


func destroy_physical_item(key: String):
	if not key in physical_items.keys():
		return
	
	var instance = physical_items[key]

	physical_items.erase(key)
	instance.on_destroy()
	instance.queue_free()
	deleted_physical_items.append(key)
	
	if state == STATE_INITIAL:
		return

	if Global.MODE1 == Global.MODE1_ONLINE:
		RPCServer.race_destroy_item.rpc_id(1, key)


func server_destroy_physical_item(key: String):
	if not key in physical_items.keys():
		return

	var instance = physical_items[key]
	physical_items.erase(key)
	instance.owned_by.active_items.erase(instance)
	instance.on_destroy()
	instance.queue_free()
	deleted_physical_items.append(key)


func send_item_state(item: PhysicalItem):
	# Only the owner can send the state
	if not item.owner_id == player_user_id:
		return
	
	var item_state = item.get_state()

	# Skip sending items that don't have a state
	if not item_state:
		return
	
	item.state_idx += 1
	
	var dto := DomainRace.ItemStateWrapper.new()
	dto.key = item.key
	dto.origin_id = item.origin_id
	dto.owner_id = item.owner_id
	dto.state = item_state
	dto.state_idx = item.state_idx
	
	if Global.MODE1 == Global.MODE1_ONLINE:
		RPCServer.race_item_state.rpc_id(1, dto.serialize())


func apply_item_state(dto: DomainRace.ItemStateWrapper):
	if dto.key in deleted_physical_items:
		return
	
	if not dto.key in physical_items.keys():
		return
	
	if dto.owner_id == player_user_id:
		return
	
	var instance := physical_items[dto.key]

	if instance.owner_id != dto.owner_id:
		return
	
	if instance.state_idx >= dto.state_idx:
		return
	
	instance.origin_id = dto.origin_id
	instance.set_state(dto.state)


func _physics_process(_delta: float) -> void:
	space_state = get_world_3d().direct_space_state
	time = get_timer_seconds()
	if state in UPDATE_STATES:
		tick += 1
	
	pause_cooldown = max(0, pause_cooldown - 1)

	match state:
		STATE_INITIAL:
			state = STATE_JOINING
			join()
		STATE_CAN_READY:
			change_state(STATE_READY_FOR_START, send_ready)
		STATE_COURSE_INTRO:
			start_course_intro()
		STATE_COUNTDOWN:
			replay_manager.setup_new_replay(self)
			state = STATE_COUNTING_DOWN
		STATE_COUNTING_DOWN:
			var ticks_to_switch := countdown_gap * (countdown_state-1) * PHYSICS_TICKS_PER_SECOND + PHYSICS_TICKS_PER_SECOND * 0.1
			if countdown_timer < ticks_to_switch:
				countdown_state -= 1
				UI.race_ui.update_countdown(countdown_state)
				if countdown_state > 0:
					Audio.play_countdown_normal()
				else:
					Audio.play_race_music(music, music_volume_multi)
			
			if countdown_timer <= 0:
				start_race()
			countdown_timer -= 1
		# STATE_RACE:
			#save_replay()
		STATE_RACE_OVER:
			#save_replay(true)
			#write_replay()
			Audio.race_music_stop()
			UI.race_ui.race_over()
			if Global.MODE1 == Global.MODE1_OFFLINE:
				# Race is over in offline mode.
				# Here we prepare the finishing times for all the CPUs and then show the rankings.
				setup_finish_order()
				state = STATE_SHOW_RANKINGS
			
			save_finish_times_to_replay()
			replay_manager.save_state(self)
			replay_manager.save_replay()
		STATE_READY_FOR_RANKINGS:
			if spectate:
				change_state(STATE_JOINING_NEXT, join_next)
			else:
				UI.race_ui.race_over()
				# TODO: Make the server send how much time?
				%NextRaceTimer.start(25)
				state = STATE_SHOW_RANKINGS
		STATE_SHOW_RANKINGS:
			UI.race_ui.hide_time()
			UI.race_ui.hide_finished()
			UI.race_ui.hide_race_over()
			handle_rankings()
		STATE_JOIN_NEXT:
			if Global.MODE1 == Global.MODE1_ONLINE:
				change_state(STATE_JOINING_NEXT, join_next)
		_:
			pass
	
	if state in UPDATE_STATES or Global.MODE1 == Global.MODE1_OFFLINE:
		# Player checkpoints
		for vehicle: Vehicle4 in players_dict.values():
			update_checkpoint(vehicle)
			if vehicle == player_camera.target:
				UI.race_ui.set_cur_lap(vehicle.lap)
		
		if Global.MODE1 == Global.MODE1_ONLINE:
			update_wait_frames += 1
			if update_wait_frames > frames_between_update:
				update_wait_frames = 0
				if player_vehicle:
					var vehicle_data: Dictionary = player_vehicle.network.get_state()
					RPCServer.race_vehicle_state.rpc_id(1, vehicle_data)
				
				for unique_id: String in physical_items.keys():
					var item := physical_items[unique_id]
					if not item.no_updates and item.owned_by == player_vehicle:
						send_item_state(item)
		
		check_finished()
	
	if state in REPLAY_STATES:
		handle_replay()

#func preload_items() -> void:
	#for key: String in Global.physical_items:
		#make_physical_item(key, player_vehicle)
	#return
#
#func remove_preload_items() -> void:
	#for key: String in physical_items:
		#destroy_physical_item(key)
	#return

func start_course_intro() -> void:
	if course_intro_tween != null:
		if Util.just_pressed_accept_or_cancel() and !player_camera.intro_skipped:
			course_intro_tween.pause()
			course_intro_tween.custom_step(999)
			skip_course_intro()
		return
	
	if not %IntroCameraAnimationPlayer.is_playing():
		intro_camera.make_current()
		for anim: String in %IntroCameraAnimationPlayer.intro_animations:
			%IntroCameraAnimationPlayer.queue(anim)
		
		course_intro_tween = create_tween()
		course_intro_tween.tween_property(UI.black_overlay, "modulate:a", 0.0, 0.25).set_delay(7.75)
		course_intro_tween.finished.connect(_on_course_intro_finished)

func _on_course_intro_finished() -> void:
	#create_tween().tween_property(UI.black_overlay, "modulate:a", 0.0, 0.25)
	start_driver_intro()

func skip_course_intro() -> void:
	%IntroCameraAnimationPlayer.play(%IntroCameraAnimationPlayer.intro_animations[%IntroCameraAnimationPlayer.intro_animations.size()-1])
	%IntroCameraAnimationPlayer.seek(10.0, true)
	player_camera.intro_skipped = true

func start_driver_intro() -> void:
	state = STATE_DRIVER_INTRO
	player_camera.driver_intro_finished.connect(_on_driver_intro_finished)
	player_camera.start_driver_intro()
	Audio.play_driver_intro_sound()
	UI.show_race_ui()

func _on_driver_intro_finished() -> void:
	if Global.MODE1 == Global.MODE1_ONLINE:
		state = STATE_CAN_READY
		return
	state = STATE_COUNTDOWN

func handle_replay() -> void:
	if state < STATE_RACE_OVER:
		replay_manager.save_state(self)
	replay_manager.advance_loaded_state(self)

func save_finish_times_to_replay() -> void:
	for user_id: int in players_dict.keys():
		replay_manager.set_finish_time(user_id, players_dict[user_id].finish_time)

func get_vehicle_distance_from_start(vehicle: Vehicle4) -> float:
	var cur_check: Checkpoint = checkpoints[vehicle.check_idx]
	var distance: float = (vehicle.lap - 1) * course_length
	distance += cur_check.length_until
	distance += cur_check.length * vehicle.check_progress
	return distance

func get_vehicle_distance_to_finish(vehicle: Vehicle4) -> float:
	var course_distance: float = course_length * lap_count
	return course_distance - get_vehicle_distance_from_start(vehicle)
	
func set_course_length() -> void:
	var length: float = 0.0
	var initial_length: float = -1
	for i in range(checkpoints.size()):
		checkpoints[i].length_until = length
		checkpoints[i].length = checkpoints[(i+1)%checkpoints.size()].global_position.distance_to(checkpoints[i].global_position)
		length += checkpoints[i].length
	course_length = length

func finish_cpus() -> void:
	var cur_seconds: float = time
	for vehicle: Vehicle4 in players_dict.values():
		if vehicle.is_player:
			continue
		if not vehicle.is_cpu or vehicle.finished:
			continue
		
		var distance_left: float = get_vehicle_distance_to_finish(vehicle)
		print(vehicle.username, " dist left: ", distance_left, " ")
		var time_left: float = distance_left / cpu_avg_speed
		time_left *= randf_range(1.0, 1.4)
		
		# Add random unluckiness
		if time_left > 6 and randf() < 0.2:
			time_left += randf_range(2, 10)
		
		vehicle.set_finished(cur_seconds + time_left)

func setup_finish_order() -> void:
	finish_cpus()  # Ensure CPUs are finished
	
	var finished_vehicles: Array = []
	var unfinished_vehicles: Array = []
	
	for user_id: int in players_dict.keys():
		if players_dict[user_id].finished:
			finished_vehicles.append(user_id)
		else:
			unfinished_vehicles.append(user_id)
	
	finished_vehicles.sort_custom(func(a: int, b: int) -> bool: return players_dict[a].finish_time < players_dict[b].finish_time)
	unfinished_vehicles.sort_custom(func(a: int, b: int) -> bool: return get_vehicle_progress(players_dict[a]) > get_vehicle_progress(players_dict[b]))
	
	finished_vehicles += unfinished_vehicles
	finish_order = finished_vehicles
	

func handle_rankings() -> void:
	if stop_rankings:
		return
	
	if rankings_timer % rankings_delay == 0:
		@warning_ignore("integer_division")
		var cur_idx: int = rankings_timer / rankings_delay
		
		if cur_idx >= len(finish_order)-1:
			stop_rankings = true
			
		var cur_vehicle: Vehicle4
		if finish_order[cur_idx] in players_dict:
			cur_vehicle = players_dict[finish_order[cur_idx]]
		else:
			cur_vehicle = removed_players_dict[finish_order[cur_idx]]
		
		var end_position = Vector2(-262, 16 + (40+5)*cur_idx)
		var start_position = end_position
		start_position.x = 800
		var new_panel := rank_panel_scene.instantiate() as RankPanel
		new_panel.set_rank(cur_idx)  # Util.make_ordinal(cur_idx+1)
		new_panel.set_username(cur_vehicle.username)
		new_panel.set_time(cur_vehicle.finish_time, cur_vehicle.finished)
		new_panel.position = start_position
		
		if cur_vehicle == player_vehicle:
			new_panel.set_border()
		
		UI.race_ui.get_node("Rankings").add_child(new_panel)
		var tween := create_tween()
		tween.tween_property(new_panel, "position", end_position, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	rankings_timer += 1

func check_finished():
	# Offline mode: All players have finished.
	# Online mode: Wait for server
	if finished:
		return
	
	if Global.MODE1 == Global.MODE1_OFFLINE:
		var is_finished: bool = true
		for vehicle: Vehicle4 in players_dict.values():
			if vehicle.is_player and not vehicle.finished:
				is_finished = false
				break
		finished = is_finished
		if finished:
			state = STATE_RACE_OVER
			Audio.race_music_stop()


func _add_vehicle(user_id: int, new_position: Vector3, look_dir: Vector3, up_dir: Vector3, ignore_replay:=false) -> Vehicle4:
	# if !ignore_replay:
	# 	replay_manager.spawn_vehicle(user_id, new_position, look_dir, up_dir)
	var new_vehicle := player_scene.instantiate() as Vehicle4
	players_dict[user_id] = new_vehicle
	vehicles_node.add_child(new_vehicle)
	new_vehicle.teleport(new_position, look_dir, up_dir)
	# new_vehicle.axis_lock()
	new_vehicle.is_player = false
	new_vehicle.world = self
	new_vehicle.user_id = user_id
	
	match Global.MODE1:
		Global.MODE1_OFFLINE:
			new_vehicle.is_cpu = true
			new_vehicle.is_network = false
			new_vehicle.username = "CPU_" + str(players_dict.size())
		Global.MODE1_ONLINE:
			new_vehicle.is_cpu = true
			new_vehicle.is_network = true
			new_vehicle.username = Network.our_room.players[user_id].username
			var path_point: EnemyPath = path_point_scene.instantiate()
			network_path_points[new_vehicle] = path_point
			path_point.visible = false
			$NetworkPathPoints.add_child(path_point)
	
	new_vehicle.cpu_logic.next_target_1 = start_enemy_points.pick_random()
	
	if user_id == player_user_id:
		new_vehicle.initialize_player()
		player_vehicle = new_vehicle
		player_camera.target = new_vehicle
		new_vehicle.username = "Player"
		if Global.MODE1 == Global.MODE1_ONLINE:
			new_vehicle.username = Config.online_username
	
	return new_vehicle

func _remove_vehicle(user_id: int):
	if user_id in players_dict.keys():
		var vehicle = players_dict[user_id]
		if player_camera.target == vehicle:
			player_camera.target = null
		vehicle.queue_free()
		# vehicle.freeze = true
		# vehicle.visible = false
		# vehicle.global_position = Vector3(0,0,-100_000)
		removed_players_dict[user_id] = players_dict[user_id]
		players_dict.erase(user_id)
		removed_player_ids.append(user_id)
		UI.race_ui.remove_nametag(user_id)


func setup_vehicles() -> void:
	var start_checkpoint := checkpoints[0] as Checkpoint
	var start_position := start_checkpoint.global_position
	var start_direction := -start_checkpoint.transform.basis.z
	var side_direction := start_checkpoint.transform.basis.x
	var up_dir := start_checkpoint.transform.basis.y
	start_position += up_dir * 1.0

	for i in range(starting_order.size()):
		var user_id: int = starting_order[i]
		
		var side_multi := 1
		if i % 2 == 1:
			side_multi = -1

		var cur_pos := start_position + start_offset_z * (i + 3) * start_direction + side_multi * start_offset_x * side_direction
		_add_vehicle(user_id, cur_pos, -start_direction, up_dir).start_side_multi = side_multi

func get_starting_order() -> Array[int]:
	match Global.MODE1:
		Global.MODE1_ONLINE:
			player_user_id = Network.peer_id
			network_room = Network.our_room as DomainRoom.Race
			if !Network.peer_id in network_room.starting_order:
				spectate = true
				return []
			
			return network_room.starting_order
		Global.MODE1_OFFLINE:
			player_user_id = 0
			var player_array: Array[int] = []

			for i in range(Global.default_player_count-1):
				player_array.append(i+1)
			player_array.append(player_user_id)
			player_array.shuffle()
			return player_array
	return []

func join():
	if Network.our_room and Network.our_room.type == DomainRoom.RoomType.LOBBY:
		join_next()
		return
	
	starting_order = get_starting_order()
	Global.player_count = max(len(starting_order), 1)
	setup_vehicles()
	#preload_items()
	#call_deferred("remove_preload_items")
	Global.final_lobby = null
	if Global.MODE1 == Global.MODE1_OFFLINE:
		UI.end_scene_change()
		state = STATE_COURSE_INTRO
		return
	
	RPCClient.race_start_received.connect(handle_race_start)
	RPCClient.race_vehicle_state_received.connect(update_vehicle_state)
	RPCClient.player_left_room_received.connect(_on_player_disconnect)
	RPCClient.race_spawn_item_received.connect(spawn_physical_item)
	RPCClient.race_destroy_item_received.connect(server_destroy_physical_item)
	RPCClient.race_item_state_received.connect(apply_item_state)
	RPCClient.race_finished_received.connect(_on_race_finished)
	RPCClient.race_item_transfer_owner_received.connect(_on_item_transfer_owner)
	RPCClient.ping_received.connect(_on_ping)

	UI.end_scene_change()
	
	if not Network.our_room or not Network.our_room.type == DomainRoom.RoomType.RACE:
		# Disconnect functions
		print("ERR: Could not connect to race")
		Debug.print("Could not connect to race")

		state = STATE_DISCONNECT
		RPCClient.error(DomainError.INVALID_ROOM)
		return
	if spectate:
		state = STATE_SPECTATING
		return
	
	skip_course_intro()
	start_driver_intro()
	return

func _on_ping(ping: float) -> void:
	if player_vehicle:
		pings[Network.peer_id] = ping

func send_ready():
	RPCServer.race_send_ready.rpc_id(1)
	print("SENDING READY")
	state = STATE_WAIT_FOR_START
	return

func get_vehicle_progress(vehicle: Vehicle4) -> float:
	var check_idx := vehicle.check_idx
	if check_idx < 0:
		check_idx = checkpoints.size() - check_idx - 2
	var cur_progress: float = 10000 * vehicle.lap + check_idx + vehicle.check_progress
	return cur_progress

func checkpoints_between_players(v1: Vehicle4, v2: Vehicle4) -> int:
	var v1_progress := get_vehicle_progress(v1)
	var v2_progress := get_vehicle_progress(v2)
	
	var diff := 0
	var amount_of_checkpoints := checkpoints.size()

	var v1_lap := floori(v1_progress / 10000)
	var v2_lap := floori(v2_progress / 10000)

	diff += (v1_lap - v2_lap) * amount_of_checkpoints

	var v1_check := floori(v1_progress) % 10000
	var v2_check := floori(v2_progress) % 10000

	diff += v1_check - v2_check

	return diff

func update_ranks() -> void:
	var ranks := []
	var ranks_vehicles := []

	var finished_vehicles := []

	for vehicle: Vehicle4 in players_dict.values():
		if vehicle.finished:
			finished_vehicles.append(vehicle)
			continue

		var cur_progress := get_vehicle_progress(vehicle)
		if not ranks:
			ranks.append(cur_progress)
			ranks_vehicles.append(vehicle)
			continue

		var stop := false
		for i in range(ranks.size()):
			if cur_progress > ranks[i]:
				ranks.insert(i, cur_progress)
				ranks_vehicles.insert(i, vehicle)
				stop = true
				break

		if stop:
			continue

		ranks.append(cur_progress)
		ranks_vehicles.append(vehicle)
	
	
	finished_vehicles.sort_custom(func(a: Vehicle4, b: Vehicle4) -> bool: return a.finish_time < b.finish_time)

	finished_vehicles.append_array(ranks_vehicles)

	for i in range(finished_vehicles.size()):
		finished_vehicles[i].set_rank(i)
	
	# UI.update_ranks(finished_vehicles)

	# print("Ranks:")
	# for vehicle: Vehicle4 in finished_vehicles.slice(0, 5):
	# 	print(vehicle.rank, " ", vehicle.finish_time)
	# print("===")

func check_advance(player: Vehicle4) -> bool:
	var next_idx := player.check_idx+1 % len(checkpoints)
	if next_idx >= len(checkpoints):
		next_idx -= len(checkpoints)
	if dist_to_checkpoint(player, next_idx) < 0:
		return false

	var next_checkpoint: Checkpoint = checkpoints[next_idx]
	
	# Don't advance to next key checkpoint if the previous key checkpoint wasn't reached
	if next_checkpoint.is_key:
		var cur_key_idx: int = key_checkpoints[next_checkpoint]
		var prev_key_idx := cur_key_idx - 1
		if prev_key_idx < 0:
			prev_key_idx = key_checkpoints.size()-1
		if prev_key_idx != player.check_key_idx and player.check_key_idx != cur_key_idx:
			return false
		player.check_key_idx = cur_key_idx

	player.check_idx = next_idx
	if next_idx == 0:
		# Crossed the finish line
		player.lap += 1
		
		if player == player_vehicle && player.lap == lap_count:
			Audio.start_final_lap(final_lap_speed_multi)
		
		if not player.finished and player.lap > lap_count and not player.is_network:
			# var time_after_finish = (timer_tick - 1) * (1.0/Engine.physics_ticks_per_second)
			var time_after_finish := time
			
			var finish_plane_normal: Vector3 = checkpoints[0].transform.basis.z
			var vehicle_vel: Vector3 = player.prev_velocity.total()
			var seconds_per_tick := 1.0/Engine.physics_ticks_per_second

			# Determine the ratio of the vehicle_vel to the finish_plane_normal, and determine how much time it had taken to cross the finish line since the last frame
			var final_time := time_after_finish - clampf(dist_to_checkpoint(player, 0) / vehicle_vel.project(finish_plane_normal).length(), 0, seconds_per_tick)
			print("Finishing ", player.username, " with time ", final_time, " ", player.finish_time, " ", time_after_finish, " ", seconds_per_tick, " ", time_after_finish - final_time)
			player.set_finished(final_time)
	
	return true

func check_reverse(player: Vehicle4) -> bool:
	var prev_idx := (player.check_idx - 1) % len(checkpoints)
	if prev_idx < 0:
		prev_idx = len(checkpoints) + prev_idx

	if dist_to_checkpoint(player, player.check_idx) > 0:
		return false

	var prev_checkpoint: Checkpoint = checkpoints[prev_idx]
	if prev_checkpoint.is_key:
		var cur_key := player.check_key_idx
		
		#Debug.print([cur_key, key_checkpoints[prev_checkpoint]])
		var prev_key: int = key_checkpoints[prev_checkpoint]
		var subtract := 0
		if prev_key == 0:
			subtract = key_checkpoints.size()
			prev_key += subtract
			cur_key += subtract
		elif cur_key == 0:
			cur_key += key_checkpoints.size()
		
		if prev_key != cur_key-1 and prev_key != cur_key:
			return false
		
		if prev_key == cur_key-1:
			player.check_key_idx = prev_key - subtract
	
	player.check_idx = prev_idx
	if prev_idx == len(checkpoints)-1:
		player.lap -= 1
	
	return true

func update_checkpoint(player: Vehicle4) -> void:
	#if player.respawn_stage:
		#return
	
	if not check_advance(player):
		check_reverse(player)

	player.check_progress = progress_in_cur_checkpoint(player)


func dist_to_checkpoint(player: Vehicle4, checkpoint_idx: int) -> float:
	var checkpoint := checkpoints[checkpoint_idx % len(checkpoints)] as Node3D
	return Util.dist_to_plane(checkpoint.transform.basis.z, checkpoint.global_position, player.get_node("%Front").global_position)


func progress_in_cur_checkpoint(player: Vehicle4) -> float:
	var dist_behind: float = abs(dist_to_checkpoint(player, player.check_idx))
	var dist_ahead: float = abs(dist_to_checkpoint(player, player.check_idx+1))
	return dist_behind / (dist_behind + dist_ahead)


func get_respawn_point(vehicle: Vehicle4) -> Dictionary:
	var out: Dictionary = {
		"position": Vector3.ZERO,
		"rotation": Vector3.ZERO,
		"gravity_zone": null
	}
	
	var cur_checkpoint := checkpoints[vehicle.check_idx] as Checkpoint
	var player_idx := players_dict.values().find(vehicle)
	
	var spawn_pos := cur_checkpoint.global_position
	var spawn_dir := -cur_checkpoint.transform.basis.z
	var side_direction := cur_checkpoint.transform.basis.x
	var up_dir := cur_checkpoint.transform.basis.y
	
	var side_multi := player_idx % 2
	if side_multi < 0:
		side_multi = -1
	
	var offset := spawn_dir * player_idx * 0.2 + side_direction * 1 * side_multi + up_dir * 3.0
	spawn_pos += offset
	
	out.position = spawn_pos
	out.rotation = cur_checkpoint.basis.get_euler()
	
	out.gravity_zone = cur_checkpoint.gravity_zone
	
	return out


func update_vehicle_state(data: DomainRace.VehicleDataWrapper) -> void:
	var user_id: int = data.player.peer_id

	if user_id == player_user_id:
		return
	
	if user_id in removed_player_ids:
		return
	
	Network.our_room.players[user_id] = data.player
	pings[user_id] = data.player.ping
	
	if not user_id in players_dict.keys():
		var cur_position: Vector3 = Util.to_vector3(data.vehicle_state["pos"])
		var cur_rotation: Vector3 = Util.to_vector3(data.vehicle_state["rot"])

		var look_dir: Vector3 = cur_rotation.normalized()
		var up_dir: Vector3 = Vector3(0, 1, 0)

		_add_vehicle(user_id, cur_position, look_dir, up_dir)
		#players_dict[user_id].axis_unlock()
		players_dict[user_id].start()
	
	players_dict[user_id].network.apply_state(data.vehicle_state)


func handle_race_start(ticks_to_start: int, tick_rate: int, ping: int) -> void:
	var seconds_left: float = Util.ticks_to_time_with_ping(ticks_to_start, tick_rate, ping)
	%StartTimer.start(seconds_left)

func _on_player_disconnect(player: DomainPlayer.Player, is_transfer: bool) -> void:
	if is_transfer:
		return
	_remove_vehicle(player.peer_id)

func _on_race_finished(data: DomainRoom.FinishData) -> void:
	print("FINISHED RECEIVED")
	finished = true
	finish_order = data.finish_order
	state = STATE_READY_FOR_RANKINGS

func _on_start_timer_timeout():
	state = STATE_COUNTDOWN


func start_race():
	state = STATE_RACE
	race_start_time = Time.get_ticks_usec()
	print("START: ", race_start_time)
	for vehicle: Vehicle4 in players_dict.values():
		# vehicle.axis_unlock()
		vehicle.start()
	#UI.race_ui.rank_label.visible = true

func join_next():
	UI.reset_race_ui()
	UI.race_ui.visible = false
	Global.menu_start_cam = lobby_cam_str
	UI.change_scene(lobby_scene)

func _on_back_pressed():
	if Global.MODE1 == Global.MODE1_ONLINE:
		state = STATE_JOIN_NEXT
	else:
		Global.menu_start_cam = menu_cam_str
		UI.change_scene(menu_scene)
		state = STATE_JOINING_NEXT

func _on_next_race_timer_timeout():
	state = STATE_JOIN_NEXT

func item_transfer_owner(item: PhysicalItem, new_owner_id: int) -> void:
	if not item or not item.key or not new_owner_id:
		return
	
	if item.owner_id != player_user_id:
		return
	
	if item.owner_id == new_owner_id:
		return
	
	var old_owner_id := item.owner_id
	item.owner_id = new_owner_id
	item._on_owner_changed(players_dict[old_owner_id], players_dict[new_owner_id])

	item.is_transferring_ownership = true
	RPCServer.race_item_transfer_owner.rpc_id(1, item.key, new_owner_id)

func _on_item_transfer_owner(key: String, new_owner_id: int):
	if not key in physical_items.keys():
		return
	if not new_owner_id in players_dict.keys():
		return
	
	var item := physical_items[key] as PhysicalItem
	var old_owner_id := item.owner_id
	item.owner_id = new_owner_id
	item.is_transferring_ownership = false

	if not old_owner_id == player_user_id:
		item._on_owner_changed(players_dict[old_owner_id], players_dict[new_owner_id])
