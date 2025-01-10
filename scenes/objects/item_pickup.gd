extends Area3D

class_name ItemPickup

@export var guaranteed_item: PackedScene = null

func _ready() -> void:
	if Global.MODE2 == Global.MODE2_TIMETRIALS:
		visible = false
		monitoring = false
		return
	
	$AnimationPlayer.play("hover")
	$AnimationPlayer.advance($AnimationPlayer.current_animation_length * randf())


func _on_body_entered(body) -> void:
	if not body is Vehicle4:
		return

	$CollisionShape3D.set_deferred("disabled", true)
	$ItemPickup.visible = false
	$RespawnTimer.start()
	body.get_item(guaranteed_item)
	


func _on_respawn_timer_timeout() -> void:
	$CollisionShape3D.disabled = false
	$ItemPickup.visible = true
