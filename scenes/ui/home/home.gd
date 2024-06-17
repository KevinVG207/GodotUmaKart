extends CanvasLayer

@export var single_scene: PackedScene
@export var online_scene: PackedScene

func _enter_tree():
	for i in range(len(Global.locales)):
		var lang: String = Global.locales[i]
		$LangSelect.add_item(tr("LANG_%s"%lang.to_upper()), i)
	$LangSelect.select(Global.cur_locale)
	$LangSelect.item_selected.connect(_on_language_change)

func _on_language_change(index: int):
	Global.cur_locale = index
	get_tree().reload_current_scene()

func _on_vs_button_pressed():
	get_tree().change_scene_to_packed(single_scene)


func _on_online_button_pressed():
	get_tree().change_scene_to_packed(online_scene)
