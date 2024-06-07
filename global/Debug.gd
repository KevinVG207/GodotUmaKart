extends CanvasLayer

@onready var rtl: RichTextLabel = $MarginContainer/RichTextLabel

func print(input):
	if is_instance_of(input, TYPE_ARRAY):
		input = " ".join(input)
	input = str(input)
	var lines: PackedStringArray = rtl.text.split("\n")
	lines.insert(0, input)
	rtl.text = "\n".join(lines.slice(0, 10))
	$EraseTimer.start()

func _on_erase_timer_timeout():
	rtl.text = ""
