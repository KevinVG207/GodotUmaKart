extends Control

class_name PauseMenu

var mainmenu_cam_str: String = "%CamFountain"
var mainmenu_scene: String = "res://scenes/ui/academy/menu_academy.tscn"

func disable() -> void:
	visible = false
	get_tree().paused = false
	#visible = false
	#%BtnPauseContinue.disabled = true
	#%BtnPauseRestart.disabled = true
	#%BtnPauseVehicle.disabled = true
	#%BtnPauseCharacter.disabled = true
	#%BtnPauseExit.disabled = true

func disable_buttons() -> void:
	%BtnPauseContinue.disabled = true
	%BtnPauseRestart.disabled = true
	%BtnPauseVehicle.disabled = true
	%BtnPauseCharacter.disabled = true
	%BtnPauseExit.disabled = true

func enable() -> void:
	visible = true
	%BtnPauseRestart.visible = false
	%BtnPauseVehicle.visible = false
	%BtnPauseCharacter.visible = false
	
	if Global.MODE2 == Global.MODE2_TIMETRIALS:
		%BtnPauseRestart.visible = true
		%BtnPauseVehicle.visible = true
		%BtnPauseCharacter.visible = true
	
	%BtnPauseContinue.disabled = false
	%BtnPauseRestart.disabled = false
	%BtnPauseVehicle.disabled = false
	%BtnPauseCharacter.disabled = false
	%BtnPauseExit.disabled = false
	%BtnPauseContinue.grab_focus()

func _enter_tree() -> void:
	visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("_pause"):
		disable()
		return

func _on_btn_pause_continue_button_down() -> void:
	disable()


func _on_btn_pause_exit_button_down() -> void:
	disable_buttons()
	Global.menu_start_cam = mainmenu_cam_str
	UI.change_scene(mainmenu_scene)
