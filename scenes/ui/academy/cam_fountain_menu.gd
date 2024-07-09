extends Control

@export var single_scene: String
@export var online_scene: String

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
	UI.change_scene(single_scene, true)


func _on_online_button_pressed():
	#UI.change_scene(online_scene)
	Global.goto_lobby_screen.emit()

func parse_input(event: InputEvent):
	print(event)
