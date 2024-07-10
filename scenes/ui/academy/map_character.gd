extends CharacterBody3D

class_name MapCharacter

@onready var nav_agent: NavigationAgent3D = $NavAgent
var gravity := Vector3.DOWN * 500.0
var move_speed := 100.0
var cur_speed := 0.0
var accel := 300.0

var cur_dir := Vector3.ZERO
var first := true
var dir_smoothing := 0.5
var target_pos:= Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("F12"):
		_on_idle_timer_timeout()


func _ready():
	var col := Color(randf(), randf(), randf())
	$NavAgent.debug_use_custom = true
	$NavAgent.debug_path_custom_color = col
	$MeshInstance3D.mesh.material.albedo_color = col
	start_idling()

func start_idling():
	$IdleTimer.start(randf_range(5, 120))

func set_next_target():
	print("Requesting next path position")
	target_pos = nav_agent.get_next_path_position()

func _physics_process(delta):
	var target_speed := 0.0
	if !nav_agent.is_navigation_finished() and $IdleTimer.is_stopped():
		var local_dest := target_pos - global_position
		var dir := local_dest.normalized()
		
		if first:
			first = false
			cur_dir = dir
		
		if cur_dir.angle_to(dir) > PI * (2.0/3.0):
			cur_dir = dir
		
		cur_dir = cur_dir.move_toward(dir, delta * dir_smoothing).normalized()
		target_speed = move_speed
	
	cur_speed = move_toward(cur_speed, target_speed, delta * accel)
	velocity = cur_dir * cur_speed
	velocity += gravity
	velocity *= delta
	
	move_and_slide()


func _on_idle_timer_timeout() -> void:
	# Choose a position to go to, and set the random stop timer.
	nav_agent.target_position = NavigationServer3D.map_get_random_point(get_parent().get_parent().get_node("NavigationRegion3D").get_navigation_map(), 1, true)
	$StopTimer.start(randf_range(10, 60))
	set_next_target()


func _on_nav_agent_target_reached() -> void:
	# Start idling
	$StopTimer.stop()
	start_idling()


func _on_stop_timer_timeout() -> void:
	# Start idling
	start_idling()


func _on_nav_agent_waypoint_reached(details: Dictionary) -> void:
	call_deferred("set_next_target")
