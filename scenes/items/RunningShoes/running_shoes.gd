extends Node3D
class_name RunningShoes

@export var texture: CompressedTexture2D
@export var from_pos: int = 1
@export var to_pos: int = 12
var local = true

var parent: Vehicle3 = null
@onready var poof: GPUParticles3D = %Poof

var started := false

var ani_multi := 2.0
var running_speed: float = 40
var use_time: float = 10
var decel_time: float = 3.5
var decel_safe: float = 0.5

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

var open: bool = false

func use(player: Vehicle3, world: RaceBase) -> RunningShoes:
	if parent == null:
		return null
	if started:
		return self
	start()
	return self

func _ready() -> void:
	%GateContainer.visible = false
	
	if parent == null:
		print("ERR: RunningShoes has no parent vehicle!")
		return

func start() -> void:
	started = true
	parent.before_update.connect(before_update)
	parent.after_update.connect(after_update)
	
	for col: CollisionShape3D in parent.standard_colliders:
		col.disabled = true
	
	for col: CollisionShape3D in $Colliders.get_children():
		colliders.append(col)
		col.reparent(parent)
	
	%Ani.play("fall")
	%SwapTimer.start()
	%GateContainer.visible = true
	
	if parent.is_player:
		parent.cpu_target = Util.get_path_point_ahead_of_player(parent)
		
	parent.is_being_controlled = true
	
	max_speed = parent.max_speed
	parent.max_speed = 0
	
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
	
	parent.max_speed = get_max_speed() if open else 0
	parent.initial_accel = initial_accel * 1.5
	parent.max_turn_speed = max_turn_speed * 2
	parent.turn_accel = turn_accel * 4
	parent.air_turn_multiplier = 1.0
	parent.stick_distance = stick_distance * 3
	parent.stick_speed = stick_speed * 3
	parent.gravity = gravity * 1.5
	parent.cpu_target_offset = Vector3.ZERO
	return

func get_max_speed() -> float:
	if %UseTimer.is_stopped():
		return max_speed
	
	# running_speed until the decel_time, where it slows down towards max_speed
	var runtime: float = use_time - %UseTimer.time_left
	return _get_max_speed(runtime, max_speed, running_speed, use_time, decel_time, decel_safe)

func _get_max_speed(x, a, b, c, d, e) -> float:
	# Return b until the final d seconds, when it linearly decreases towards a
	# e is a little safezone at the end where we are guaranteed to be at a
	return clamp((-(b-a)/(d-e))*(x-c+e)+a, a, b)

func after_update(_delta: float):
	if open:
		parent.cani.speed_scale = (parent.cur_speed / running_speed) * ani_multi
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
	parent.cpu_target_offset = parent.get_random_target_offset()

func remove() -> void:
	poof.finished.connect(func() -> void: poof.queue_free())
	poof.reparent(parent, true)
	poof.emitting = true
	if parent != null:
		parent.call_deferred("remove_item")


func _on_open_timer_timeout() -> void:
	open = true
	%UseTimer.start(use_time)
	%Ani.play("disappear")
	%Ani.animation_finished.connect(_on_disappeared)

func _on_disappeared(_anim_name: String) -> void:
	%GateContainer.visible = false


func _on_swap_timer_timeout() -> void:
	poof.emitting = true
	call_deferred("swap")

func swap() -> void:
	parent.cani.play("running_shoes_run")
	parent.hide_kart()
	%OpenTimer.start()


func _on_use_timer_timeout() -> void:
	remove()
