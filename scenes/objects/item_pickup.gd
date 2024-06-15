extends Area3D

class_name ItemPickup

func _ready():
	$AnimationPlayer.play("hover")
	$AnimationPlayer.advance($AnimationPlayer.current_animation_length * randf())


func _on_body_entered(body):
	print("Colliding with ", body)
	$CollisionShape3D.set_deferred("disabled", true)
	$ItemPickup.visible = false
	$RespawnTimer.start()


func _on_respawn_timer_timeout():
	$CollisionShape3D.disabled = false
	$ItemPickup.visible = true
