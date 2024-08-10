extends Control

@export var single_scene: String
@export var online_scene: String
@onready var last_button: Control = %VSButton
var given_focus := false

func _enter_tree():
	for i in range(len(Global.locales)):
		var lang: String = Global.locales[i]
		$LangSelect.add_item(tr("LANG_%s"%lang.to_upper()), i)
	$LangSelect.select(Global.cur_locale)
	$LangSelect.item_selected.connect(_on_language_change)
	
	%VSButton.pressed.connect(_on_vs_button_pressed)
	%OnlineButton.pressed.connect(_on_online_button_pressed)

func _on_language_change(index: int):
	Global.cur_locale = index
	#get_tree().reload_current_scene()

func _on_vs_button_pressed():
	if not given_focus:
		return
	UI.change_scene(single_scene, true)
	last_button = %VSButton

# func _input(event: InputEvent) -> void:
# 	print(event)

func _on_online_button_pressed():
	#UI.change_scene(online_scene)
	if not given_focus:
		return
	Global.goto_lobby_screen.emit()
	last_button = %OnlineButton

func focus():
	last_button.grab_focus()
