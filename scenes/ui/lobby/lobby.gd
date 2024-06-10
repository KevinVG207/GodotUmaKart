extends CanvasLayer

const STATE_RESET = -2
const STATE_RESETTING = -1
const STATE_INITIAL = 0
const STATE_SETUP = 1
const STATE_SETUP_COMPLETE = 2
const STATE_PRE_MATCHMAKING = -3
const STATE_MATCHMAKING = 3
const STATE_MATCHMAKING_WAIT = 4
const STATE_MATCHMAKING_COMLETE = 5
const STATE_JOINING = 6
const STATE_START_VOTING = 7
const STATE_VOTING = 8
const STATE_VOTED = 9
const STATE_READY = 10

class lobbyOp:
	const CLIENT_VOTE = 1
	const SERVER_VOTE_DATA = 2
	const SERVER_MATCH_DATA = 3


var state = STATE_RESETTING
var wait_frames = 0
var max_wait = 60 * 60

@export var info_box: PackedScene
var info_boxes: Dictionary = {}
@onready var box_container: GridContainer = $MarginContainer/PlayerInfoContainer


func _physics_process(_delta):
	match state:
		STATE_RESETTING:
			change_state(STATE_RESET, reset)
		STATE_INITIAL:
			change_state(STATE_SETUP, setup)
		STATE_SETUP_COMPLETE:
			$Status.text = "Connected to server"
			$MatchmakeButton.disabled = false
			$MatchmakeButton.visible = true
		STATE_PRE_MATCHMAKING:
			change_state(STATE_MATCHMAKING, matchmake)
		STATE_MATCHMAKING_WAIT:
			if Network.ready_match:
				$Status.text = "Match found"
				state = STATE_MATCHMAKING_COMLETE
		STATE_MATCHMAKING_COMLETE:
			change_state(STATE_JOINING, join)
		STATE_START_VOTING:
			change_state(STATE_START_VOTING, setup_voting)
		STATE_READY:
			pass
		_:
			pass

func change_state(new_state: int, state_func: Callable = Callable()):
	state = new_state
	state_func.call()

func reset():
	$Status.text = "Resetting network connection..."
	await Network.reset()
	state = STATE_INITIAL

func setup():
	$Status.text = "Setting up connection..."
	
	var res: bool = await Network.connect_client()
	
	if not res:
		$Status.text = "Connection failed!"
		state = STATE_INITIAL
		return
	
	state = STATE_SETUP_COMPLETE

func matchmake():
	$Status.text = "Looking for match..."
	
	var res: bool = await Network.matchmake()
	
	if not res:
		$Status.text = "Failed to matchmake!"
		state = STATE_RESET
		return
	
	wait_frames = 0
	state = STATE_MATCHMAKING_WAIT
	return

func join():
	$Status.text = "Joining match..."
	
	var res: bool = await Network.join_match(Network.ready_match)
	
	#Network.socket.received_match_presence.connect(_on_match_presence)
	Network.socket.received_match_state.connect(_on_match_state)

	if not res or not Network.cur_match:
		# Disconnect functions
		#Network.socket.received_match_presence.disconnect(_on_match_presence)
		Network.socket.received_match_state.disconnect(_on_match_state)

		$Status.text = "Failed to join match!"
		state = STATE_RESET
		return
	
	state = STATE_START_VOTING
	return

func setup_voting():
	$Status.text = "Waiting for votes..."
	state = STATE_VOTING
	return

func add_player(username: String, session_id: String):
	if session_id in info_boxes:
		return
	
	var new_box = info_box.instantiate() as LobbyPlayerInfoBox
	new_box.get_node("Label").text = username
	info_boxes[session_id] = new_box
	box_container.add_child(new_box)


func remove_player(session_id: String):
	if not session_id in info_boxes:
		return
	var cur_box = info_boxes[session_id] as LobbyPlayerInfoBox
	box_container.remove_child(cur_box)
	info_boxes.erase(session_id)
	cur_box.queue_free()


func _on_matchmake_button_pressed():
	if state == STATE_SETUP_COMPLETE:
		$MatchmakeButton.disabled = true
		$MatchmakeButton.visible = false
		state = STATE_PRE_MATCHMAKING


#func _on_match_presence(p_presence : NakamaRTAPI.MatchPresenceEvent):
	#for p in p_presence.joins:
		#add_player(p.user_id.substr(0, 10), p.user_id)
	#for p in p_presence.leaves:
		#remove_player(p.user_id)

func _on_match_state(match_state : NakamaRTAPI.MatchData):
	var data: Dictionary = JSON.parse_string(match_state.data)
	match match_state.op_code:
		lobbyOp.SERVER_VOTE_DATA:
			print("Received vote data")
			handle_vote_data(data)
			pass
		lobbyOp.SERVER_MATCH_DATA:
			print("Received match data")
			pass
		_:
			print("Unknown lobby op code: ", match_state.op_code)

func handle_vote_data(data: Dictionary):
	var presences = data.presences as Dictionary
	var votes = data.votes as Dictionary
	
	var cur_session_ids = info_boxes.keys()
	var server_session_ids = presences.keys()
	
	for session_id: String in cur_session_ids:
		if not session_id in server_session_ids:
			remove_player(session_id)
	
	for p in presences.values():
		if p.sessionId in cur_session_ids:
			continue
		add_player(p.userId.substr(0, 10), p.sessionId)
	
	print(data)
