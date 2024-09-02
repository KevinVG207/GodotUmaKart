extends Control

var given_focus := false

signal back

var SETTING_CYCLE: PackedScene = preload("res://scenes/ui/cycle_setting.tscn")
var SETTING_BIND: PackedScene = preload("res://scenes/ui/bind_setting.tscn")

var descriptions: Dictionary = {}

@onready var settings_element: PackedScene = preload("res://scenes/ui/academy/settings_element.tscn")

func _ready() -> void:
	# Language setting
	var lang_ele: CycleSetting = SETTING_CYCLE.instantiate()
	for lang in Global.locales:
		lang_ele.add_item("LANG_%s"%lang.to_upper())
	lang_ele.select(Global.cur_locale)
	lang_ele.item_selected.connect(_on_language_change)
	add_setting(%General, lang_ele, "SETTING_LANG", "SETTING_LANG_DESCR")
	
	add_bindings()

func add_bindings():
	var actions := Config.current_bindings
	for action: String in actions:
		if action.begins_with("_") or action.to_upper().begins_with("UI_"):
			continue
		
		print(action, ": ", actions[action])
		
		for type: String in actions[action]:
			if actions[action][type] == null:
				continue
			var bind: int = actions[action][type]
			var tab: VBoxContainer
			
			match type:
				"JOYPAD":
					tab = %Joypad
				"JOYPAD_AXIS":
					tab = %Joypad
				"KEYBOARD":
					tab = %Keyboard
				"MOUSE":
					tab = %Keyboard
			
			var label_str: String = "SETTING_" + action.to_upper()
			var descr_str = label_str + "_DESCR"
			
			var bind_ele: BindSetting = SETTING_BIND.instantiate()
			bind_ele.action = action
			bind_ele.type = type
			bind_ele.bind = bind
			bind_ele.reload()
			
			add_setting(tab, bind_ele, label_str, descr_str)
			print(action, " ", type, " ", bind)

func add_setting(grid: VBoxContainer, setting_ele: Control, label_str: String, descr_str: String):
	var cont: SettingsElement = settings_element.instantiate() as SettingsElement
	var label: Label = cont.get_node("%Label")
	
	label.text = label_str
	
	descriptions[setting_ele] = descr_str
	
	setting_ele.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont.add_child(setting_ele)
	
	grid.add_child(cont)
	
	var on_hover := func(): %Description.text = descriptions[setting_ele]
	cont.focus_entered.connect(on_hover)
	cont.mouse_entered.connect(on_hover)

func _on_btn_apply_pressed() -> void:
	back.emit()


func _on_btn_cancel_pressed() -> void:
	back.emit()

func _on_language_change(index: int, _text: String):
	Global.cur_locale = index
