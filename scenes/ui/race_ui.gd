extends Control

func update_speed(speed):
	$Speed.text = str(int(speed))

func update_countdown(cd):
	$Countdown.text = str(cd)
