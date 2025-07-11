extends CanvasLayer

@onready var rtl: RichTextLabel = $MarginContainer/RichTextLabel

func _physics_process(_delta: float) -> void:
	$FPS.text = "FPS: " + str(Engine.get_frames_per_second())

func print(input: Variant) -> void:
	if not rtl:
		return
	
	if is_instance_of(input, TYPE_ARRAY):
		input = " ".join(input)
	input = str(input)
	var lines: PackedStringArray = rtl.text.split("\n")
	lines.insert(0, input)
	rtl.text = "\n".join(lines.slice(0, 15))
	$EraseTimer.start()

func _on_erase_timer_timeout() -> void:
	clear()

func clear() -> void:
	rtl.text = ""

func pd_clear() -> void:
	%PlayerDebug.text = ""

func pd_print(input: Variant, var_name: String) -> void:
	var out: String = " " + var_name + ": "
	if is_instance_of(input, TYPE_ARRAY):
		for ele: Variant in input:
			out += str(ele) + " "
	else:
		out += str(input)
	%PlayerDebug.text = %PlayerDebug.text + out + "\n"

func item_dist_clear() -> void:
	%ItemDist.text = ""

func item_dist_print(item_name: String, chance: float) -> void:
	var out: String = " " + item_name + ": " + str(chance)
	%ItemDist.text = %ItemDist.text + out + "\n"
