extends CanvasLayer

@export var single_scene: PackedScene
@export var online_scene: PackedScene

func _on_vs_button_pressed():
	get_tree().change_scene_to_packed(single_scene)


func _on_online_button_pressed():
	get_tree().change_scene_to_packed(online_scene)
