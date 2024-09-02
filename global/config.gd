extends Node

var default_bindings: Dictionary
var current_bindings: Dictionary
var keybinds_path: String = "user://keybinds.json"

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
				actions[action]["JOYPAD_AXIS"] = event.axis
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
		for type: String in actions[action]:
			if actions[action][type] == null:
				continue
			var bind: int = actions[action][type]

			var event := make_event(type, bind)
			if not event:
				continue
			
			InputMap.action_add_event(action, event)

func make_event(type, bind) -> InputEvent:
	var event: InputEvent = null
	
	match type:
		"JOYPAD":
			event = InputEventJoypadButton.new()
			event.button_index = bind
		"JOYPAD_AXIS":
			event = InputEventJoypadMotion.new()
			event.axis = bind
		"KEYBOARD":
			event = InputEventKey.new()
			event.physical_keycode = bind
		"MOUSE":
			event = InputEventMouseButton.new()
			event.button_index = bind

	return event

func save_bindings(actions: Dictionary) -> void:
	print("Saving bindings")
	var store_file: FileAccess = FileAccess.open(keybinds_path, FileAccess.WRITE)
	store_file.store_string(JSON.stringify(actions))
	store_file.close()

func load_bindings() -> Dictionary:
	print("Loading bindings")
	var out: Dictionary = {}
	var load_file: FileAccess = FileAccess.open(keybinds_path, FileAccess.READ)
	var parsed_binds: Variant = JSON.parse_string(load_file.get_as_text(true))
	if parsed_binds:
		for action: String in parsed_binds.keys():
			if not InputMap.has_action(action):
				print("Removing action ", action)
				parsed_binds.erase(action)
		out = parsed_binds
	
	return out

func _ready():
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
