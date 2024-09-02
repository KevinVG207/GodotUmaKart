extends Control

@export var single_scene: String
@export var online_scene: String


func _on_vs_button_pressed():
	UI.change_scene(single_scene, true)


func _on_online_button_pressed():
	UI.change_scene(online_scene)
