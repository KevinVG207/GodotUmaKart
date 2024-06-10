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

var vote_timeout_set = false
var cur_vote = ""
var cur_votes = {}

@export var info_box: PackedScene
var info_boxes: Dictionary = {}
@onready var box_container: GridContainer = $MarginContainer/PlayerInfoContainer

func _ready():
	# print(Util.get_race_courses())
	# get_tree().quit()
	pass

func _process(_delta):
	# Deal with displaying things
	$TimeLeft.text = "0:00"

	if not $VoteTimeout.is_stopped():
		$TimeLeft.text = Util.format_time_minutes($VoteTimeout.time_left)


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
	$VoteButton.disabled = false
	$VoteButton.visible = true
	return

func add_player(username: String, session_id: String):
	if session_id in info_boxes:
		return
	
	var new_box = info_box.instantiate() as LobbyPlayerInfoBox
	new_box.get_node("Name").text = username
	info_boxes[session_id] = new_box
	box_container.add_child(new_box)


func remove_player(session_id: String):
	if not session_id in info_boxes:
		return
	var cur_box = info_boxes[session_id] as LobbyPlayerInfoBox
	box_container.remove_child(cur_box)
	info_boxes.erase(session_id)
	cur_box.queue_free()

func update_player_name(session_id: String, new_name: String):
	if not session_id in info_boxes:
		return
	info_boxes[session_id].get_node("Name").text = new_name

func update_player_pick(session_id: String, pick_text: String):
	if not session_id in info_boxes:
		return
	info_boxes[session_id].get_node("Pick").text = pick_text

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
	var cur_tick = data.curTick as int
	var vote_timeout = data.voteTimeout as int
	var tick_rate = data.tickRate as int
	
	# Setup vote timeout:
	if not vote_timeout_set:
		vote_timeout_set = true
		var ticks_left = max(vote_timeout - cur_tick, 0)
		var seconds_left = ticks_left / tick_rate
		$VoteTimeout.start(seconds_left)
	
	var cur_session_ids = info_boxes.keys()
	var server_session_ids = presences.keys()
	
	for session_id: String in cur_session_ids:
		if not session_id in server_session_ids:
			remove_player(session_id)
	
	for p in presences.values():
		if p.sessionId in cur_session_ids:
			continue
		add_player(p.userId.substr(0, 10), p.sessionId)
	
	cur_votes = votes
	print("Cur Votes: ", cur_votes)
	for session_id in votes:
		var vote_data: Dictionary = votes[session_id]
		update_player_pick(session_id, vote_data['course'])


func _on_vote_button_pressed():
	$VoteButton.disabled = true
	$VoteButton.visible = false

	cur_vote = Util.get_race_courses()[0]

	var res = await vote()
	return res

func vote():
	var payload = {
		"course": cur_vote
	}

	var res = await Network.send_match_state(lobbyOp.CLIENT_VOTE, payload)

	if not res:
		$Status.text = "Failed to send vote!"
		state = STATE_RESET
		return false
	
	state = STATE_VOTED
	return true

func _on_vote_timeout_timeout():
	$VoteButton.disabled = true
	$VoteButton.visible = false
	
	if not cur_vote:
		cur_vote = Util.get_race_courses()[0]
	
	var res = await vote()
	return res
