extends Control

func _ready() -> void:
	var descr_text = tr("NETWORK_ERROR_" + str(Global.error_code))
	if !descr_text:
		descr_text = tr("NETWORK_ERROR_GENERIC")
	%Description.text = descr_text
	%Code.text = tr("NETWORK_ERROR_CODE") % Global.error_code
	
	%ContinueButton.grab_focus()


func _on_continue_button_pressed() -> void:
	Global.menu_start_cam = "%CamTrunk"
	UI.change_scene("res://scenes/ui/academy/menu_academy.tscn")
