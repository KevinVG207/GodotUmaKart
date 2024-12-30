extends CanvasLayer

class_name LineEditPopup

var parent: CustomLineEdit = null
var initial_text: String = ""
var max_chars: int = 0


func _ready() -> void:
	if not parent:
		print("ERR: LineEditPopup has no parent CustomLineEdit!")
	
	%LineEdit.text = initial_text
	%LineEdit.max_length = max_chars
	%LineEdit.grab_focus()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and %LineEdit.has_focus():
		# This should not be needed but for some reason backspace is not working!
		# TODO: Find the cause of this ^
		print(event.physical_keycode)
		if event.physical_keycode == 4194308:
			if %LineEdit.has_selection():
				var sel_start: int = %LineEdit.get_selection_from_column()
				var sel_end: int = %LineEdit.get_selection_to_column()
				%LineEdit.text = %LineEdit.text.erase(sel_start, sel_end - sel_start)
				%LineEdit.caret_column = sel_start
			else:
				var caret_pos: int = %LineEdit.caret_column
				if caret_pos > 0:
					%LineEdit.text = %LineEdit.text.erase(caret_pos-1)
					%LineEdit.caret_column = caret_pos - 1
		if event.physical_keycode == 4194319:
			# Left arrow key
			if %LineEdit.has_selection():
				var caret_target: int = %LineEdit.get_selection_from_column()
				%LineEdit.deselect()
				%LineEdit.caret_column = caret_target
			else:
				%LineEdit.caret_column -= 1
		if event.physical_keycode == 4194321:
			# Right arrow key
			if %LineEdit.has_selection():
				var caret_target: int = %LineEdit.get_selection_to_column()
				%LineEdit.deselect()
				%LineEdit.caret_column = caret_target
			else:
				%LineEdit.caret_column += 1
			
		
	if event is InputEventKey and event.physical_keycode == 4194309:
		exit()
		return
	
	if event is InputEventJoypadButton:
		if event.button_index == Config.current_bindings.brake.JOYPAD:
			exit()
			return

func exit() -> void:
	Global.menu_ignore_input = false
	if parent:
		parent.text = %LineEdit.text
		parent.grab_focus()
		Config.online_username = parent.text
		Config.update_config()
		parent.set_deferred("is_open", false)
	else:
		print("ERR: LineEditPopup tried to apply text to null parent!")
	queue_free()


func _on_color_rect_gui_input(event: InputEvent) -> void:
	# Close if clicked outside of textbox
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		exit()
		return
