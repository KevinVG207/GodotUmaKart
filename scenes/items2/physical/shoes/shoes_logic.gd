extends LogicItem

@onready var root: Node3D = $Root
@onready var ani: AnimationPlayer = $Root/Ani
@onready var poof: GPUParticles3D = $Root/Poof

var has_transformed: bool = false
var has_disappeared: bool = false
@onready var fall_time: float = ani.get_animation("fall").length
var fall_frames: int = 0
@onready var disappear_time: float = ani.get_animation("disappear").length
var disappear_frames: int = 0
@export var decel_time: float = 1.5
var decel_frames: int = 0
var decelerating: bool = false
@export var max_active_time: float = 10.0
var active_frames: int = 0

var speed_scale: float = 1.5

@onready var initial_speed_multi: float = speed_multi

var total_frames: int:
	get():
		return fall_frames + disappear_frames + active_frames + decel_frames

var frame: int = 0

func _ready() -> void:
	root.reparent(owned_by, false)
	ani.play("fall")
	root.visible = true
	
	ani.speed_scale = speed_scale
	fall_frames = roundi(world.PHYSICS_TICKS_PER_SECOND * fall_time / speed_scale)
	disappear_frames = roundi(world.PHYSICS_TICKS_PER_SECOND * disappear_time / speed_scale)
	decel_frames = roundi(world.PHYSICS_TICKS_PER_SECOND * decel_time)
	active_frames = roundi(world.PHYSICS_TICKS_PER_SECOND * max_active_time)
	owned_by.cpu_logic.new_target(Util.get_path_point_ahead_of_player(owned_by))

func _physics_process(_delta: float) -> void:
	if frame >= total_frames:
		destroy()
		return
	
	if frame >= fall_frames and !has_transformed:
		has_transformed = true
		do_damage_type = Vehicle4.DamageType.SPIN
		ani.play("disappear")
		poof.emitting = true
		owned_by.call_deferred("hide_kart")
		
	if frame >= fall_frames + disappear_frames and !has_disappeared:
		has_disappeared = true
	
	if has_disappeared and !decelerating:
		root.visible = false
		if owned_by.rank == 0:
			active_frames = 0
	
	active_frames = maxi(active_frames, 0)
	
	if frame >= fall_frames + disappear_frames + active_frames:
		decelerating = true
		var ratio: float = clampf(float(frame - (fall_frames + disappear_frames + active_frames)) / decel_frames, 0, 1)
		speed_multi = remap(ratio, 0, 1, initial_speed_multi, 1.0)
	
	frame += 1

func on_destroy() -> void:
	poof.reparent(owned_by.visual_node)
	poof.restart()
	poof.emitting = true
	poof.delete_self = true
	owned_by.call_deferred("show_kart")
	root.queue_free()
	return
