extends Control

@export var single_scene: String
@export var online_scene: String
@onready var last_button: Control = %VSButton
var given_focus := false

signal to_lobby
signal to_settings
signal to_title

func _enter_tree():
	%VSButton.pressed.connect(_on_vs_button_pressed)

func _on_language_change(index: int, _text: String):
	Config.cur_locale = index
	#get_tree().reload_current_scene()

func _on_vs_button_pressed():
	if not given_focus:
		return
	UI.change_scene(single_scene, true)
	last_button = %VSButton

#func _input(event: InputEvent) -> void:
	#print(event)

func _on_online_button_pressed():
	if not given_focus:
		return
	to_lobby.emit()
	last_button = %OnlineButton

func focus():
	last_button.grab_focus()


func _on_settings_button_pressed() -> void:
	if not given_focus:
		return
	to_settings.emit()
	last_button = %SettingsButton


func _on_title_button_pressed() -> void:
	if not given_focus:
		return
	to_title.emit()
	last_button = %VSButton
