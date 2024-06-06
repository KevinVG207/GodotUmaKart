extends Node


var should_setup: bool = false
var port: int = 8001

var socket = WebSocketPeer.new()
var json = JSON.new()

#func _ready():
	#

func websocket_connect():
	var err = socket.connect_to_url("wss://umapyoi.net/ws")
	print(err)

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	print(state)
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var packet_data: PackedByteArray = socket.get_packet()
			var json_data = packet_data.get_string_from_utf8()
			print("Packet: ", packet_data)
			print("JSON: ", json_data)
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		#print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		#set_process(false) # Stop processing.

func send_data(data: Variant):
	var json_data = JSON.stringify(data)
	socket.send_text(json_data)
