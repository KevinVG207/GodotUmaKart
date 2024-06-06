extends CanvasLayer

func print(input):
	if is_instance_of(input, TYPE_ARRAY):
		input = " ".join(input)
	input = str(input)
	var lines: PackedStringArray = $MarginContainer/RichTextLabel.text.split("\n")
	lines.insert(0, input)
	$MarginContainer/RichTextLabel.text = "\n".join(lines.slice(0, 10))
	$EraseTimer.start()

func _on_erase_timer_timeout():
	$MarginContainer/RichTextLabel.text = ""

