extends Camera3D

var target: Node3D = null
var offset: Vector3 = Vector3(-5, 2, 0)
var look_offset: Vector3 = Vector3(0, 1, 0)
var lerp_speed: float = 10.0

func _physics_process(delta):
	if !target:
		return
		
	var target_transform = target.global_transform.translated_local(offset)
	global_transform = global_transform.interpolate_with(target_transform, lerp_speed*delta)
	
	look_at(target.global_transform.origin + look_offset, target.transform.basis.y)
