extends Node3D
class_name RunningShoes

@export var texture: CompressedTexture2D
@export var from_pos: int = 1
@export var to_pos: int = 12
var local := true

var parent: Vehicle4 = null
@onready var poof: GPUParticles3D = %Poof

var started := false

var ani_multi := 2.0
var running_speed: float = 40
var use_time: float = 15
var decel_time: float = 3.5
var decel_safe: float = 0.5
var start_speed: float = 5.0

var base_max_speed := 0.0
var base_initial_accel := 0.0
var max_turn_speed := 0.0
var base_turn_accel := 0.0
var air_turn_multiplier := 0.0
var stick_speed := 0.0
var base_grip := 0.0
var gravity := Vector3.DOWN
#var weight := 0.0

var colliders: Array = []

var open: bool = false

func use(player: Vehicle4, world: RaceBase) -> RunningShoes:
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

# TODO: Rework this now that Vehicle4 is rewritten
func start() -> void:
	started = true
	parent.before_update.connect(before_update)
	parent.after_update.connect(after_update)
	
	for col: CollisionShape3D in parent.standard_colliders:
		col.set_deferred("disabled", true)
	
	for col: CollisionShape3D in $Colliders.get_children():
		colliders.append(col)
		col.reparent(parent)
	
	%Ani.play("fall")
	%SwapTimer.start()
	%GateContainer.visible = true
	
	if parent.is_player:
		parent.cpu_logic.target = Util.get_path_point_ahead_of_player(parent)
		
	parent.is_controlled = true
	parent.use_cpu_logic = true
	
	base_max_speed = parent.base_max_speed
	parent.base_max_speed = start_speed
	
	base_initial_accel = parent.base_initial_accel
	parent.base_initial_accel *= 1.5
	
	max_turn_speed = parent.max_turn_speed
	parent.max_turn_speed *= 2
	
	base_turn_accel = parent.base_turn_accel
	parent.base_turn_accel *= 4
	
	air_turn_multiplier = parent.air_turn_multiplier
	parent.air_turn_multiplier = 1.0
	
	stick_speed = parent.stick_speed
	parent.stick_speed *= 3
	
	base_grip = parent.base_grip
	parent.base_grip *= 2.0
	
	gravity = parent.gravity
	parent.gravity *= 1.5
	
	#weight = parent.weight;
	#parent.weight *= 3

func before_update(_delta: float) -> void:
	if parent.is_player:
		parent.is_cpu = true
	
	parent.base_max_speed = get_max_speed() if open else start_speed
	parent.base_initial_accel = base_initial_accel * 1.5
	parent.max_turn_speed = max_turn_speed * 2
	parent.base_turn_accel = base_turn_accel * 4
	parent.air_turn_multiplier = 1.0
	parent.stick_speed = stick_speed * 3
	parent.gravity = gravity * 1.5
	#parent.weight = weight * 3
	parent.cpu_logic.target_offset = Vector3.ZERO
	if open:
		parent.do_damage_type = Vehicle4.DamageType.SPIN
	return

func get_max_speed() -> float:
	if %UseTimer.is_stopped():
		return base_max_speed
	
	# running_speed until the decel_time, where it slows down towards max_speed
	var runtime: float = use_time - %UseTimer.time_left
	return _get_max_speed(runtime, base_max_speed, running_speed, use_time, decel_time, decel_safe)

func _get_max_speed(x: float, a: float, b: float, c: float, d: float, e: float) -> float:
	# Return b until the final d seconds, when it linearly decreases towards a
	# e is a little safezone at the end where we are guaranteed to be at a
	return clamp((-(b-a)/(d-e))*(x-c+e)+a, a, b)

func after_update(_delta: float) -> void:
	if open:
		parent.cani.speed_scale = (parent.cur_speed / running_speed) * ani_multi
		parent.hide_kart()

func _exit_tree() -> void:
	if parent == null:
		return
	
	if !started:
		return
	
	if parent.is_player:
		parent.is_cpu = false
	
	for col: CollisionShape3D in parent.standard_colliders:
		col.disabled = false
	
	for col: CollisionShape3D in colliders:
		col.queue_free()
	
	open = false
	
	parent.is_controlled = false
	parent.use_cpu_logic = false
	parent.audio.engine_sound_enabled = true
	
	parent.show_kart()
	parent.cani.play("sit")
	parent.base_max_speed = base_max_speed
	parent.base_initial_accel = base_initial_accel
	parent.max_turn_speed = max_turn_speed
	parent.base_turn_accel = base_turn_accel
	parent.air_turn_multiplier = air_turn_multiplier
	parent.stick_speed = stick_speed
	parent.base_grip = base_grip
	parent.gravity = gravity
	parent.cpu_logic.target_offset = parent.cpu_logic.get_random_target_offset()
	parent.do_damage_type = Vehicle4.DamageType.NONE
	#parent.weight = weight

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
	parent.audio.engine_sound_enabled = false
	%OpenTimer.start()


func _on_use_timer_timeout() -> void:
	remove()
