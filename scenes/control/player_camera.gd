extends Camera3D

var target: Vehicle3 = null
var offset: Vector3 = Vector3(-5, 2, 0)
var offset_bw: Vector3 = Vector3(5, 2, 0)
#var offset: Vector3 = Vector3(0, 2, 5)
var look_offset: Vector3 = Vector3(0, 1.2, 0)
var lerp_speed: float = 12
var lerp_speed_look: float = 15
var look_target: Array = []
#var look_target = Vector3.INF
@onready var cur_pos: Vector3 = position
@onready var cur_pos_bw: Vector3 = position
var cur_target: Vector3 = Vector3.INF

var forwards = true

func _physics_process(delta):
	if !target:
		return
	
	#var instant: bool = false
	#if Input.is_action_just_pressed("mirror"):
		#cur_offset = offset
		#cur_offset.x *= -1
		#instant = true
	#elif Input.is_action_just_released("mirror"):
		#cur_offset = offset
		#instant = true
	
	# var cur_forward = true
	# if target.cur_speed < 0:
	# 	cur_forward = false
	# 	cur_offset = Vector3(-offset.x, offset.y, offset.z)
	
	cur_pos = cur_pos.lerp(target.global_transform.translated_local(offset).origin, lerp_speed * delta)
	cur_pos_bw = cur_pos_bw.lerp(target.global_transform.translated_local(offset_bw).origin, lerp_speed * delta)

	# var swap = false
	# if cur_forward != forwards:
	# 	swap = true
	
	# if swap:
	# 	global_transform = target_transform
	# else:
	# 	global_transform = global_transform.interpolate_with(target_transform, lerp_speed*delta)
	
	if Input.is_action_pressed("mirror"):
		position = cur_pos_bw
	else:
		position = cur_pos
	
	var true_target: Vector3 = target.global_transform.origin + look_offset

	look_target.insert(0, true_target)
	look_target = look_target.slice(0, 3)
	
	var avg_target: Vector3 = Util.sum(look_target)/len(look_target)
	
	if cur_target == Vector3.INF:
		cur_target = avg_target

	cur_target = cur_target.lerp(avg_target, lerp_speed_look * delta)
	
	look_at(cur_target, -target.gravity.normalized())

	# forwards = cur_forward
