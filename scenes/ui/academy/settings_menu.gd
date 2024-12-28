extends Control

var given_focus := false

signal back

var SETTING_CYCLE: PackedScene = preload("res://scenes/ui/cycle_setting.tscn")
var SETTING_BIND: PackedScene = preload("res://scenes/ui/bind_setting.tscn")
var SETTING_AUDIO: PackedScene = preload("res://scenes/ui/audio_setting.tscn")

var setting_elements: Array = []

var prev_config: Dictionary
var prev_bindings: Dictionary

@onready var settings_element: PackedScene = preload("res://scenes/ui/academy/settings_element.tscn")

func _ready() -> void:
	disable_reset_button()
	Global.goto_settings_screen.connect(first_time_setup)
	setup()

func first_time_setup() -> void:
	setup()
	%TabContainer.current_tab = 0

func focus():
	%BtnApply.grab_focus()

func setup() -> void:
	# Clear containers
	setting_elements.clear()
	Util.remove_children(%Graphics)
	Util.remove_children(%Keyboard)
	Util.remove_children(%Joypad)
	Util.remove_children(%Audio)
	
	prev_config = Config.current_config.duplicate(true)
	prev_bindings = Config.current_bindings.duplicate(true)
	
	# Language setting
	var lang_ele: CycleSetting = SETTING_CYCLE.instantiate()
	for lang: String in Config.locales:
		lang_ele.add_item("LANG_%s"%lang.to_upper())
	lang_ele.select(Config.cur_locale)
	lang_ele.item_selected.connect(_on_language_change)
	add_setting(%Graphics, lang_ele, "SETTING_LANG")
	
	# Window/fullscreen setting
	add_config_cyclesetting(%Graphics, Config.window_modes, Config.window_mode, "SETTING_WINDOWMODE", _on_windowmode_change)
	
	# Vsync mode
	add_config_cyclesetting(%Graphics, Config.vsync_modes, Config.vsync_mode, "SETTING_VSYNC", _on_vsync_change)
	
	# Max FPS
	add_config_cyclesetting(%Graphics, Config.max_fps_modes, Config.max_fps_mode, "SETTING_MAXFPS", _on_maxfps_change)

	# Key bindings
	add_bindings()
	
	# Audio
	add_audio()


func add_config_cyclesetting(container: VBoxContainer, config_array: Array, default: int, label_str: String, change_func: Callable) -> void:
	var ele: CycleSetting = SETTING_CYCLE.instantiate()
	for i in range(len(config_array)):
		ele.add_item(label_str + "_%d"%i)
	ele.select(default)
	ele.item_selected.connect(change_func)
	add_setting(container, ele, label_str)


func add_bindings() -> void:
	var actions := Config.current_bindings
	var actions_list: Array = actions.keys()
	actions_list.sort()
	for action: String in actions_list:
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
			
			var bind_ele: BindSetting = SETTING_BIND.instantiate()
			bind_ele.action = action
			bind_ele.type = type
			bind_ele.bind = bind
			bind_ele.reload()
			bind_ele.updated.connect(_on_bind_update)
			
			add_setting(tab, bind_ele, label_str)

func add_audio() -> void:
	#AudioServer
	
	# Loop over all buses
	# If bus sends to Master (or IS Master), add setting element
	print("Add Audio")
	print(AudioServer.bus_count)
	for bus_idx: int in range(AudioServer.bus_count):
		print(bus_idx)
		if bus_idx == 0 or AudioServer.get_bus_send(bus_idx) == "Master":
			add_volume_slider(bus_idx)

func add_volume_slider(bus_idx) -> void:
	var bus_name := AudioServer.get_bus_name(bus_idx)
	var audio_ele: AudioSetting = SETTING_AUDIO.instantiate()
	audio_ele.set_bus(bus_name)
	#audio_ele.add_item("AUDIO_%s"%bus_name.to_upper())
	#audio_ele.select(0)
	#audio_ele.item_selected.connect(_on_language_change)
	add_setting(%Audio, audio_ele, "SETTING_AUDIO_%s"%bus_name.to_upper())

func add_setting(grid: VBoxContainer, setting_ele: Control, label_str: String) -> void:
	var cont: SettingsElement = settings_element.instantiate() as SettingsElement
	var label: Label = cont.get_node("%Label")
	
	label.text = label_str
	
	setting_elements.append(setting_ele)
	
	setting_ele.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont.add_child(setting_ele)
	
	grid.add_child(cont)
	
	var on_hover := func() -> void: %Description.text = label_str + "_DESCR"
	cont.focus_entered.connect(on_hover)
	cont.mouse_entered.connect(on_hover)

func _on_btn_apply_pressed() -> void:
	Config.update_config()
	Config.update_bindings()
	given_focus = false
	back.emit()


func _on_btn_cancel_pressed() -> void:
	Config.apply_config(prev_config)
	Config.apply_bindings(prev_bindings)
	setup()

func _on_language_change(index: int, _text: String) -> void:
	Config.cur_locale = index

func _on_windowmode_change(index: int, _text: String) -> void:
	Config.window_mode = index

func _on_maxfps_change(index: int, _text: String) -> void:
	Config.max_fps_mode = index

func _on_vsync_change(index: int, _text: String) -> void:
	Config.vsync_mode = index

func _on_tab_container_tab_changed(tab: int) -> void:
	var tab_ele: VBoxContainer = %TabContainer.get_child(tab)
	%Description.text = tab_ele.name + "_DESCR"
	
	if tab == 1 or tab == 2:
		enable_reset_button()
	else:
		disable_reset_button()

func enable_reset_button() -> void:
	%BtnResetBinds.visible = true
	%BtnResetBinds.disabled = false

func disable_reset_button() -> void:
	%BtnResetBinds.visible = false
	%BtnResetBinds.disabled = true

func _on_bind_update() -> void:
	for ele: Control in setting_elements:
		if ele is BindSetting:
			Config.current_bindings[ele.action][ele.type] = ele.bind
	Config.apply_bindings(Config.current_bindings)

func _input(event: InputEvent) -> void:
	if Global.rebind_popup:
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("brake"):
		_on_btn_cancel_pressed()
		_on_btn_apply_pressed()
	
	if event.is_action_pressed("ui_up"):
		if %BtnApply.has_focus() or %BtnCancel.has_focus() or %BtnResetBinds.has_focus():
			%TabContainer.get_tab_bar().grab_focus()
			get_viewport().set_input_as_handled()


func _on_btn_reset_binds_pressed() -> void:
	Config.current_bindings = Config.default_bindings.duplicate(true)
	Config.apply_bindings(Config.current_bindings)
	setup()
