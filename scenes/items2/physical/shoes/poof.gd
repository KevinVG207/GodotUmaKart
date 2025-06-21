extends GPUParticles3D

var delete_self: bool = false
var frame: int = 60

func _physics_process(_delta: float) -> void:
	if frame <= 0:
		queue_free()
		return
	
	if delete_self:
		frame -= 1
