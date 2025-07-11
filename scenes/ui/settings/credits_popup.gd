extends CanvasLayer

class_name CreditsPopup

# Must set parent!
var parent: CamFountainMenu = null
@onready var label: MarkdownLabel = %MarkdownLabel
var step_multi: int = 5

func _ready() -> void:
	Global.menu_ignore_input = true
	%MarkdownLabel.display_file("res://credits.md")
	%BtnCancel.grab_focus()

func close() -> void:
	Global.menu_ignore_input = false
	if !parent:
		print("Err: CreditsPopup not given a parent!")
	parent.give_credits_btn_focus()
	queue_free()

func _process(delta: float) -> void:
	if Util.just_pressed_accept_or_cancel():
		close()
	
	var scrollbar := label.get_v_scroll_bar()
	if Input.is_action_pressed("ui_down"):
		scrollbar.value += scrollbar.step * step_multi
	if Input.is_action_pressed("ui_up"):
		scrollbar.value -= scrollbar.step * step_multi


func _on_background_gui_input(event: InputEvent) -> void:
	# Close if clicked outside of textbox
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		close()


func _on_btn_cancel_pressed() -> void:
	close()
