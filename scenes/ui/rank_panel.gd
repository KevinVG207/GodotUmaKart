extends Panel

class_name RankPanel

@export var style_normal: StyleBoxFlat
@export var style_border: StyleBoxFlat

func set_border():
	self["theme_override_styles/panel"] = style_border

func set_username(name: String) -> void:
	%PlayerName.text = name

func set_rank(idx: int) -> void:
	%Rank.text = tr("ORD_%d" % (idx+1))

func set_time(seconds: float, finished: bool = true) -> void:
	if not finished:
		%Time.text = tr("RACE_DNF")
	else:
		%Time.text = Util.format_time_ms(seconds)
