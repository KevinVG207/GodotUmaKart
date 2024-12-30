extends CanvasLayer

class_name ExitPopup

# Must set parent!
var parent: CamFountainMenu = null

func _ready() -> void:
	Global.menu_ignore_input = true
	%BtnCancel.grab_focus()

func close() -> void:
	Global.menu_ignore_input = false
	if !parent:
		print("Err: ExitPopup not given a parent!")
	parent.give_exit_btn_focus()
	queue_free()

func exit() -> void:
	get_tree().quit()

func _on_btn_cancel_pressed() -> void:
	close()


func _on_btn_exit_pressed() -> void:
	exit()


func _on_background_gui_input(event: InputEvent) -> void:
	# Close if clicked outside of textbox
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		close()
