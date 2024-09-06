extends Button

class_name CustomLineEdit

var popup_scene: PackedScene = preload("res://scenes/ui/_elements/CustomLineEdit/line_edit_popup.tscn")

@export var max_chars: int = 0
var is_open: bool = false
var countdown: int = 0

func _process(_delta: float) -> void:
	# TODO: This is stupid
	if !is_open and countdown > 0:
		countdown -= 1

func _on_pressed() -> void:
	if is_open:
		return
	
	var popup: LineEditPopup = popup_scene.instantiate()
	popup.parent = self
	popup.initial_text = text
	popup.max_chars = max_chars
	is_open = true
	countdown = 10
	get_window().add_child(popup)
