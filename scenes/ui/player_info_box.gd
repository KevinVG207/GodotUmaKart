extends PanelContainer

class_name LobbyPlayerInfoBox

@export var current_user_color: Color
@export var picked_color: Color

func set_username(new_name: String):
	%Name.text = new_name

func set_pick(pick_text: String):
	%Pick.text = pick_text

func set_cur_user():
	%Name.modulate = current_user_color

func set_picked():
	get_theme_stylebox("panel").bg_color = picked_color
