extends Node

var default_config: Dictionary
var current_config: Dictionary
var config_path: String = "user://config.json"

var default_bindings: Dictionary
var current_bindings: Dictionary
var keybinds_path: String = "user://keybinds.json"


##### Settings #####

var locales := [
	"en",
	"ja"
]

var cur_locale: int = 0:
	set(value):
		if value < 0 or value >= len(locales):
			return
		TranslationServer.set_locale(locales[value])
		cur_locale = value

var window_modes := [
	DisplayServer.WINDOW_MODE_WINDOWED,
	DisplayServer.WINDOW_MODE_FULLSCREEN,
	DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
]

var window_mode: int = 0:
	set(value):
		if value < 0 or value >= len(window_modes):
			return
		window_mode = value
		DisplayServer.window_set_mode(window_modes[value])


var max_fps_modes := [
	60,
	120,
	144,
	240,
	0
]

var max_fps_mode: int = 4:
	set(value):
		if value < 0 or value >= len(max_fps_modes):
			return
		Engine.max_fps = max_fps_modes[value]
		max_fps_mode = value


var vsync_modes := [
	DisplayServer.VSYNC_DISABLED,
	DisplayServer.VSYNC_ENABLED,
	DisplayServer.VSYNC_ADAPTIVE
]

var vsync_mode: int = 2:
	set(value):
		if value < 0 or value >= len(vsync_modes):
			return
		DisplayServer.window_set_vsync_mode(vsync_modes[value])
		vsync_mode = value


##### End Settings #####


func _enter_tree() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	TranslationServer.set_locale(locales[cur_locale])
	

func make_config() -> Dictionary:
	print("Making config")
	var config: Dictionary = {}
	
	config.language = locales[cur_locale]
	config.window_mode = window_mode
	config.max_fps_mode = max_fps_mode
	config.vsync_mode = vsync_mode
	
	return config

func apply_config(config: Dictionary) -> void:
	print("Applying config")
	if "language" in config:
		var loc_idx := locales.find(config.language)
		if loc_idx >= 0:
			cur_locale = loc_idx
	if "window_mode" in config:
		window_mode = config.window_mode
	if "max_fps_mode" in config:
		max_fps_mode = config.max_fps_mode
	if "vsync_mode" in config:
		vsync_mode = config.vsync_mode

func save_config(config: Dictionary) -> void:
	print("Saving config")
	Util.save_json(config_path, config)

func load_config() -> Dictionary:
	print("Loading config")
	var out: Dictionary = {}
	var config: Variant = Util.load_json(config_path)
	if config:
		for setting: String in config.keys():
			if setting not in default_config:
				print("Removing setting ", setting)
				config.erase(setting)
		out = config
	
	return out

func get_bindings() -> Dictionary:
	# Turn InputMap bindings into editable/savable dictionary.
	print("Getting bindings")
	var actions: Dictionary = {}
	
	for action: StringName in InputMap.get_actions():
		actions[action] = {"JOYPAD": null, "JOYPAD_AXIS": null, "KEYBOARD": null, "MOUSE": null}
		
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		if not events:
			continue
		
		for event: InputEvent in events:
			if event is InputEventJoypadButton:
				actions[action]["JOYPAD"] = event.button_index
			if event is InputEventJoypadMotion:
				var _sign: int = 1 if event.axis_value >= 0 else -1
				actions[action]["JOYPAD_AXIS"] = (event.axis + 1) * _sign
			if event is InputEventKey:
				actions[action]["KEYBOARD"] = event.physical_keycode
			if event is InputEventMouseButton:
				actions[action]["MOUSE"] = event.button_index
	return actions

func apply_bindings(actions: Dictionary) -> void:
	# Apply actions dictionary to InputMap
	print("Applying bindings")
	for action: String in actions:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for type: String in actions[action]:
			if actions[action][type] == null:
				continue
			var bind: int = actions[action][type]

			var event := make_event(type, bind)
			if not event:
				continue
			
			InputMap.action_add_event(action, event)

func make_event(type: String, bind: int) -> InputEvent:
	var event: InputEvent = null
	
	match type:
		"JOYPAD":
			event = InputEventJoypadButton.new()
			event.button_index = bind
		"JOYPAD_AXIS":
			event = InputEventJoypadMotion.new()
			var _sign: int = 1 if bind >= 0 else -1
			event.axis = abs(bind) - 1
			event.axis_value = _sign
		"KEYBOARD":
			event = InputEventKey.new()
			event.physical_keycode = bind
		"MOUSE":
			event = InputEventMouseButton.new()
			event.button_index = bind

	return event

func save_bindings(actions: Dictionary) -> void:
	print("Saving bindings")
	Util.save_json(keybinds_path, actions)

func load_bindings() -> Dictionary:
	print("Loading bindings")
	var out: Dictionary = {}
	var parsed_binds: Variant = Util.load_json(keybinds_path)
	if parsed_binds:
		for action: String in parsed_binds.keys():
			if not InputMap.has_action(action):
				print("Removing action ", action)
				parsed_binds.erase(action)
		out = parsed_binds
	
	return out

func update_config() -> void:
	current_config = make_config()
	save_config(current_config)

func update_bindings() -> void:
	current_bindings = get_bindings()
	save_bindings(current_bindings)

func _ready() -> void:
	default_config = make_config()
	current_config = default_config
	
	# Ensure config file exists.
	if not FileAccess.file_exists(config_path):
		save_config(default_config)
	
	# Load current config and apply.
	if FileAccess.file_exists(config_path):
		var config := load_config()
		if config:
			current_config = config
			apply_config(config)
	
	
	default_bindings = get_bindings()
	current_bindings = default_bindings
	
	# Ensure keybind file exists.
	if not FileAccess.file_exists(keybinds_path):
		save_bindings(default_bindings)
	
	# Load current bindings and apply.
	if FileAccess.file_exists(keybinds_path):
		var binds := load_bindings()
		if binds:
			current_bindings = binds
			apply_bindings(binds)
