extends Control

var given_focus := false

signal back

var SETTING_CYCLE: PackedScene = preload("res://scenes/ui/cycle_setting.tscn")
var SETTING_BIND: PackedScene = preload("res://scenes/ui/bind_setting.tscn")

var descriptions: Dictionary = {}

var prev_config: Dictionary
var prev_bindings: Dictionary

@onready var settings_element: PackedScene = preload("res://scenes/ui/academy/settings_element.tscn")

func _ready() -> void:
	setup()
	Global.goto_settings_screen.connect(setup)

func setup() -> void:
	# Clear containers
	Util.remove_children(%General)
	Util.remove_children(%Keyboard)
	Util.remove_children(%Joypad)
	
	prev_config = Config.current_config.duplicate(true)
	prev_bindings = Config.current_bindings.duplicate(true)
	
	# Language setting
	var lang_ele: CycleSetting = SETTING_CYCLE.instantiate()
	for lang in Global.locales:
		lang_ele.add_item("LANG_%s"%lang.to_upper())
	lang_ele.select(Global.cur_locale)
	lang_ele.item_selected.connect(_on_language_change)
	add_setting(%General, lang_ele, "SETTING_LANG", "SETTING_LANG_DESCR")
	
	# Key bindings
	add_bindings()
	
	%TabContainer.current_tab = 0

func add_bindings():
	var actions := Config.current_bindings
	for action: String in actions:
		if action.begins_with("_") or action.to_upper().begins_with("UI_"):
			continue
		
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
	Config.current_config = Config.make_config()
	Config.current_bindings = Config.get_bindings()
	Config.save_config(Config.current_config)
	Config.save_bindings(Config.current_bindings)
	back.emit()


func _on_btn_cancel_pressed() -> void:
	Config.apply_config(prev_config)
	Config.apply_bindings(prev_bindings)
	setup()
	back.emit()

func _on_language_change(index: int, _text: String):
	Global.cur_locale = index


func _on_tab_container_tab_changed(tab: int) -> void:
	var tab_ele: VBoxContainer = %TabContainer.get_child(tab)
	%Description.text = tab_ele.name + "_DESCR"
