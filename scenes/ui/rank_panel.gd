extends Panel

class_name RankPanel

@export var style_normal: StyleBoxFlat
@export var style_border: StyleBoxFlat

func set_border():
	self["theme_override_styles/panel"] = style_border
