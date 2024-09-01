extends Control

var given_focus := false

signal back

var SETTING_CYCLE: PackedScene = preload("res://scenes/ui/cycle_setting.tscn")

var descriptions: Dictionary = {}

@onready var settings_element: PackedScene = preload("res://scenes/ui/academy/settings_element.tscn")

func _ready() -> void:
	var lang_strings := []
	for lang in Global.locales:
		lang_strings.append("LANG_%s"%lang.to_upper())
	add_setting(%General, SETTING_CYCLE, "SETTING_LANG", "SETTING_LANG_DESCR", lang_strings, Global.cur_locale).item_selected.connect(_on_language_change)

func add_setting(grid: VBoxContainer, setting_type: PackedScene, label_str: String, descr_str: String, values: Array, default: int=0) -> Control:
	var cont: SettingsElement = settings_element.instantiate() as SettingsElement
	var label: Label = cont.get_node("%Label")
	var ele: Control = setting_type.instantiate()
	
	label.text = label_str
	for value in values:
		ele.add_item(value)
	ele.select(default)
	
	descriptions[ele] = descr_str
	
	ele.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont.add_child(ele)
	
	grid.add_child(cont)
	
	var on_hover := func(): %Description.text = descriptions[ele]
	cont.focus_entered.connect(on_hover)
	cont.mouse_entered.connect(on_hover)
	
	return ele

func _on_btn_apply_pressed() -> void:
	back.emit()


func _on_btn_cancel_pressed() -> void:
	back.emit()

func _on_language_change(index: int, _text: String):
	Global.cur_locale = index
