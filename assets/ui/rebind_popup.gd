extends ColorRect

class_name RebindPopup

var action: String = ""
var type: String = ""
var parent: BindSetting = null
var is_joypad: bool = false
var prev_key: int

func _ready() -> void:
	# Avoid multiple popups.
	if Global.rebind_popup:
		print("ERR: rebind_popup is already assigned to Global")
		queue_free()
		return
	
	if not action or not type:
		print("ERR: No action or type in rebind_popup")
		queue_free()
		return
	
	if not parent:
		print("ERR: No parent in rebind_popup")
		queue_free()
		return
	
	if not prev_key:
		print("ERR: No prev_key in rebind_popup")
		queue_free()
		return
	
	Global.rebind_popup = self
	
	%ActionLabel.text = tr("SETTINGS_TYPE_" + type) + " - " + tr("SETTING_" + action.to_upper())

func exit(key: int) -> void:
	Global.rebind_popup = null
	parent.update(key)
	queue_free()

func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		exit(prev_key)
		return
	
	if is_joypad and event is InputEventJoypadButton and parent.type == "JOYPAD":
		exit(event.button_index)
		return
	if is_joypad and event is InputEventJoypadMotion and parent.type == "JOYPAD_AXIS":
		exit(event.axis)
		return
	if !is_joypad and event is InputEventKey and parent.type == "KEYBOARD":
		exit(event.physical_keycode)
		return
