extends Camera3D

var target: Vehicle3 = null
var offset: Vector3 = Vector3(-5, 2, 0)
#var offset: Vector3 = Vector3(0, 2, 5)
var look_offset: Vector3 = Vector3(0, 1, 0)
var lerp_speed: float = 10.0
var look_target: Array = []

var forwards = true

func _physics_process(delta):
	if !target:
		return

	var cur_offset = offset
	# var cur_forward = true
	# if target.cur_speed < 0:
	# 	cur_forward = false
	# 	cur_offset = Vector3(-offset.x, offset.y, offset.z)
	
	var target_transform = target.global_transform.translated_local(cur_offset)

	# var swap = false
	# if cur_forward != forwards:
	# 	swap = true
	
	# if swap:
	# 	global_transform = target_transform
	# else:
	# 	global_transform = global_transform.interpolate_with(target_transform, lerp_speed*delta)
	global_transform = global_transform.interpolate_with(target_transform, lerp_speed*delta)
	
	var true_target: Vector3 = target.global_transform.origin + look_offset

	# if swap:
	# 	look_target = []

	look_target.insert(0, true_target)
	look_target = look_target.slice(0, 5)
	
	var avg_target: Vector3 = Util.sum(look_target)/len(look_target)
	
	look_at(avg_target, -target.gravity.normalized())

	# forwards = cur_forward
