extends Control

signal item_selected(index: int)

var items: Dictionary = {}
var selected: int = -1
var button: PackedScene = preload("res://scenes/ui/dropdown_button.tscn")

func add_item(item: String) -> void:
	if item in items:
		return
	
	var instance = button.instantiate() as Button
	instance.text = item
	%ButtonContainer.add_child(instance)
	items[item] = instance
	instance.pressed.connect(func(): select(len(items)-1))

func select(index: int) -> void:
	if len(items)-1 < index:
		return
	selected = index
	%Panel.visible = false
	item_selected.emit(index)


func _on_button_pressed() -> void:
	%Panel.visible = !%Panel.visible
