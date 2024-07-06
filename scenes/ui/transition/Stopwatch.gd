extends TextureRect

var cur_progress: float = 0.0
var move_speed: float = 800
#var lerp_multi: float = 10.0
@onready var ani: AnimationPlayer = $"../AnimationPlayer"
var already_continued: bool = false

func _process(delta):
	var progress: float = get_parent().progress
	progress = progress * 360
	var cur_move_speed = remap(max(270, cur_progress), 270, 360, move_speed, move_speed * 0.05)
	cur_progress = move_toward(cur_progress, progress, delta * cur_move_speed)
	#cur_progress = lerp(cur_progress, progress, delta * lerp_multi)
	$Hand.rotation_degrees = cur_progress
	
	if ani.current_animation == "end" and cur_progress < 337.5:
		ani.seek(0.0)
