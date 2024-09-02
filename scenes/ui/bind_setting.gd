extends Control

class_name BindSetting

var action := ""
var type := ""
var bind: int = -1

func _ready():
	pass

func reload():
	if bind < 0:
		return
	
	var event := Config.make_event(type, bind)
	if not event:
		return
	
	var btn_text := event.as_text()
	
	if btn_text.find("(") >= 0 and btn_text.find(")") >= 0:
		btn_text = btn_text.substr(0, btn_text.find("(")-1)
	
	%Button.text = btn_text

func _on_button_pressed() -> void:
	pass # Replace with function body.
