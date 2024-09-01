extends Control

class_name CycleSetting

signal item_selected(index: int, item: String)

@export var selected: int = 0
@export var items: PackedStringArray = []

func _ready():
	if selected >= 0 and selected < len(items):
		%Label.text = tr(items[selected])

func add_item(item: String) -> void:
	if item in items:
		return
	items.append(item)

func select(idx: int) -> void:
	idx = idx % len(items)
	selected = idx
	item_selected.emit(idx, items[idx])
	%Label.text = tr(items[idx])

func _on_btn_left_pressed() -> void:
	select(selected-1)

func _on_btn_right_pressed() -> void:
	select(selected+1)
