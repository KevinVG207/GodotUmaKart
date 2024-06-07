extends Node

var port: int = 8001

var send_index: int = 0
var socket: WebSocketPeer = null
var json := JSON.new()
var mutex: Mutex
var thread := Thread.new()
var should_exit := false
var vehicle_data: Dictionary = {}
var sending_vehicle_data := false
var unique_id: String = ""
var fetching_id := false
var fetching_states := false
var cur_vehicle_states: Dictionary = {}
var cur_index: int = -1

func _ready():
	mutex = Mutex.new()
	thread.start(poll)

func _connect():
	mutex.lock()
	unique_id = ""
	mutex.unlock()
	socket = WebSocketPeer.new()
	socket.connect_to_url("wss://umapyoi.net/ws")

func poll():
	while true:
		mutex.lock()
		var _should_exit = should_exit
		mutex.unlock()
		
		if _should_exit:
			break
		
		if not socket:
			_connect()

		socket.poll()
		var state = socket.get_ready_state()
		#print(state)
		if state == WebSocketPeer.STATE_OPEN:
			while socket.get_available_packet_count():
				var packet_data: PackedByteArray = socket.get_packet()
				var res = json.parse(packet_data.get_string_from_utf8())
				
				if res != 0:
					print("ERR: ", error_string(res))
					continue
				
				var data = json.data
				handle_data(data)

		elif state == WebSocketPeer.STATE_CLOSING:
			# Keep polling to achieve proper close.
			pass
		elif state == WebSocketPeer.STATE_CONNECTING:
			pass
		else:
			_connect()
		
		mutex.lock()
		var _vehicle_data = vehicle_data
		mutex.unlock()
		
		if _vehicle_data and not sending_vehicle_data:
			sending_vehicle_data = true
			var res = send_vehicle_data(_vehicle_data)
			if res:
				mutex.lock()
				vehicle_data.clear()
				mutex.unlock()
			else:
				sending_vehicle_data = false
			# Send vehicle data
			
			# send_data(_vehicle_data, "vehicle_data")
		
		if get_unique_id().is_empty() and not fetching_id:
			fetching_id = true
			var res = fetch_unique_id()
			if not res:
				fetching_id = false
		
		mutex.lock()
		var _cur_vehicle_states = cur_vehicle_states
		mutex.unlock()
		
		if not fetching_states and not _cur_vehicle_states:
			fetching_states = true
			var ret = fetch_vehicle_states()
			if not ret:
				fetching_states = false


func handle_data(_data: Dictionary):
	if 'type' not in _data or 'data' not in _data or 'index' not in _data or 'md5' not in _data:
		return
	
	var type: String = _data['type']
	var str_data: String = _data['data']
	var index: int = _data['index']
	var md5: String = _data['md5']

	var new_md5: String = str_data.md5_text()
	if not new_md5 == md5:
		return
	
	var res = json.parse(str_data)
	if res != 0:
		print("ERR: ", error_string(res))
		return
	
	var data: Variant = json.data
	
	var ret = false
	mutex.lock()
	print(thread.get_id(), " IDX: ", cur_index, " ", index)
	if index <= cur_index:
		ret = true
	else:
		cur_index = index
	mutex.unlock()
	
	if ret:
		return
	
	if type == "vehicle_data_received":
		sending_vehicle_data = false
	elif type == "unique_id_received":
		mutex.lock()
		unique_id = str(data)
		mutex.unlock()
		fetching_id = false
	elif type == "unique_id_expired":
		mutex.lock()
		unique_id = ""
		mutex.unlock()
	elif type == "vehicles":
		mutex.lock()
		cur_vehicle_states = data
		mutex.unlock()
		fetching_states = false


func send_data(data: Variant, type: String):
	if not socket:
		return false
	var state = socket.get_ready_state()
	if not state == WebSocketPeer.STATE_OPEN:
		return false
	
	print("Sending type " + type)
	
	send_index += 1
	
	var packet: Dictionary = {
		'index': send_index,
		'type': type,
		'data': data
	}
	var json_data = JSON.stringify(packet)
	socket.send_text(json_data)
	return true

func fetch_unique_id():
	return send_data(true, "generate_unique_id")
	
func get_unique_id():
	mutex.lock()
	var id: String = unique_id
	mutex.unlock()
	return id

func send_vehicle_data(state: Dictionary):
	if get_unique_id().is_empty():
		return false
	var data = {
		"id": get_unique_id(),
		"state": state
	}
	return send_data(data, "vehicle_data")

func fetch_vehicle_states():
	if get_unique_id().is_empty():
		return false
	
	return send_data(true, "get_vehicles")
