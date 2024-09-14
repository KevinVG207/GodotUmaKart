extends Node3D
class_name RunningShoes

var parent: Vehicle3 = null

var ani_multi := 2.0

var max_speed := 0.0
var initial_accel := 0.0
var max_turn_speed := 0.0
var turn_accel := 0.0
var air_turn_multiplier := 0.0
var stick_distance := 0
var stick_speed := 0.0
var default_grip := 0.0
var air_decel := 0.0
var gravity := Vector3.DOWN

var colliders: Array = []

func _ready() -> void:
	if parent == null:
		print("ERR: RunningShoes has no parent vehicle!")
		return
	
	parent.before_update.connect(before_update)
	parent.after_update.connect(after_update)
	
	for col: CollisionShape3D in parent.standard_colliders:
		col.disabled = true
	
	for col: CollisionShape3D in $Colliders.get_children():
		colliders.append(col)
		col.reparent(parent)
	
	parent.cani.play("running_shoes_run")
	parent.hide_kart()
	
	if parent.is_player:
		parent.cpu_target = Util.get_path_point_ahead_of_player(parent)
		
	parent.is_being_controlled = true
	
	max_speed = parent.max_speed
	parent.max_speed = 45
	
	initial_accel = parent.initial_accel
	parent.initial_accel *= 1.5
	
	max_turn_speed = parent.max_turn_speed
	parent.max_turn_speed *= 2
	
	turn_accel = parent.turn_accel
	parent.turn_accel *= 4
	
	air_turn_multiplier = parent.air_turn_multiplier
	parent.air_turn_multiplier = 1.0
	
	stick_distance = parent.stick_distance
	parent.stick_distance *= 3
	
	stick_speed = parent.stick_speed
	parent.stick_speed *= 3
	
	air_decel = parent.air_decel
	parent.air_decel = 1.0
	
	default_grip = parent.default_grip
	parent.default_grip *= 2.0
	
	gravity = parent.gravity
	parent.gravity *= 1.5

func before_update(_delta: float) -> void:
	if parent.is_player:
		parent.is_cpu = true
	
	parent.max_speed = 45
	parent.initial_accel = initial_accel * 1.5
	parent.max_turn_speed = max_turn_speed * 2
	parent.turn_accel = turn_accel * 4
	parent.air_turn_multiplier = 1.0
	parent.stick_distance = stick_distance * 3
	parent.stick_speed = stick_speed * 3
	parent.gravity = gravity * 1.5
	return

func after_update(_delta: float):
	parent.cani.speed_scale = (parent.cur_speed / parent.max_speed) * ani_multi
	parent.hide_kart()

func _exit_tree() -> void:
	if parent == null:
		return
	
	if parent.is_player:
		parent.is_cpu = false
	
	for col: CollisionShape3D in parent.standard_colliders:
		col.disabled = false
	
	for col: CollisionShape3D in colliders:
		col.queue_free()
	
	parent.is_being_controlled = false
	
	parent.show_kart()
	parent.cani.play("sit")
	parent.max_speed = max_speed
	parent.initial_accel = initial_accel
	parent.max_turn_speed = max_turn_speed
	parent.turn_accel = turn_accel
	parent.air_turn_multiplier = air_turn_multiplier
	parent.stick_distance = stick_distance
	parent.stick_speed = stick_speed
	parent.air_decel = air_decel
	parent.default_grip = default_grip
	parent.gravity = gravity
