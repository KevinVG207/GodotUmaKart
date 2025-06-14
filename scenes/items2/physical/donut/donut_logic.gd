extends LogicItem

var colliders: Array[CollisionShape3D] = []
@export var time_active: float = 8.0
@export var start_anim: Curve
@export var start_anim_time: float = 1.2
@export var end_anim: Curve
@export var end_anim_time: float = 0.8

var is_big: bool = false
var big_frames: int = 0
var total_frames: int = 0
var frame: int = 0

func _ready() -> void:
	owned_by.do_damage_type = Vehicle4.DamageType.SQUISH
	owned_by.item_speed_multi = 1.2
	
	var latency: float = 0.0

	if owned_by != world.player_vehicle and owned_by.is_network == true:
		# Spawned by a network player; apply latency
		if owned_by.user_id in world.pings:
			latency += world.pings[owned_by.user_id] * 0.001
		if world.player_vehicle.user_id in world.pings:
			latency += world.pings[world.player_vehicle.user_id] * 0.001
	
	latency = min(latency, time_active / 2.0)

	time_active -= latency
	Debug.print(latency)

	big_frames = roundi(world.PHYSICS_TICKS_PER_SECOND * time_active)
	total_frames = big_frames + roundi(world.PHYSICS_TICKS_PER_SECOND * end_anim_time)

func _physics_process(_delta: float) -> void:
	if frame >= total_frames:
		destroy()
		return
	
	if !is_big:
		set_start_size()
	
	if frame > big_frames:
		owned_by.do_damage_type = Vehicle4.DamageType.NONE
		owned_by.item_speed_multi = 1.0
		set_end_size()
	
	frame += 1

func on_destroy() -> void:
	reset_size()
	owned_by.do_damage_type = Vehicle4.DamageType.NONE
	owned_by.item_speed_multi = 1.0

func _set_size(size: float) -> void:
	owned_by.vani.scale = size
	
	for collider: CollisionShape3D in colliders.duplicate():
		colliders.erase(collider)
		collider.queue_free()
	
	for source: CollisionShape3D in owned_by.standard_colliders:
		var collider: CollisionShape3D = CollisionShape3D.new()
		collider.shape = source.shape.duplicate()
		collider.rotation = source.rotation
		collider.scale *= size
		colliders.append(collider)
		owned_by.add_child(collider)
		collider.position = source.position * size

func set_start_size() -> void:
	var anim_pos: float = frame / float(world.PHYSICS_TICKS_PER_SECOND)
	if anim_pos >= start_anim_time:
		is_big = true
		anim_pos = start_anim_time
	var anim_ratio: float = anim_pos / start_anim_time
	var size: float = start_anim.sample(anim_ratio)
	_set_size(size)

func set_end_size() -> void:
	var anim_pos: float = (frame - big_frames) / float(world.PHYSICS_TICKS_PER_SECOND)
	if anim_pos >= end_anim_time:
		anim_pos = end_anim_time
	var anim_ratio: float = anim_pos / end_anim_time
	var size: float = end_anim.sample(anim_ratio)
	_set_size(size)

func reset_size() -> void:
	for collider in colliders:
		owned_by.remove_child(collider)
		collider.queue_free()
		owned_by.vani.scale = 1.0
