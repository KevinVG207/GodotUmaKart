extends Control

const STATE_IDLE = -99
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
const STATE_MATCH_RECEIVED = 10
const STATE_SWITCHING_SCENE = 11

class lobbyOp:
	const SERVER_PING = 0
	const CLIENT_VOTE = 1
	const SERVER_VOTE_DATA = 2
	const SERVER_MATCH_DATA = 3
	const SERVER_ABORT = 4


var state: int
var vote_timeout_started = false

var cur_vote = ""
var cur_votes = {}
var next_course = ""
var given_focus := false

signal back

@export var info_box: PackedScene
var info_boxes: Dictionary = {}
@onready var box_container: GridContainer = %PlayerInfoContainer


func _ready():
	state = STATE_IDLE
	if Network.ready_match:
		state = STATE_MATCHMAKING_COMLETE
	Global.goto_lobby_screen.connect(start)


func start():
	if state != STATE_IDLE:
		return
	state = STATE_RESETTING


func _process(_delta):
	# Deal with displaying things
	$TimeLeft.text = "0:00"

	if vote_timeout_started and info_boxes.size() <= 1:
		$TimeLeft.text = tr("LOBBY_WAIT_PLAYERS")
	elif vote_timeout_started and not $VoteTimeout.is_stopped():
		$TimeLeft.text = Util.format_time_minutes($VoteTimeout.time_left)
	else:
		$TimeLeft.text = ""
	
	if given_focus:
		if Input.is_action_just_pressed("brake") and %UsernameEdit.countdown == 0:
			$LeaveButton.pressed.emit()
			$LeaveButton.grab_focus()


func _physics_process(_delta):
	match state:
		STATE_RESETTING:
			change_state(STATE_RESET, reset)
		STATE_INITIAL:
			change_state(STATE_SETUP, setup)
		STATE_SETUP_COMPLETE:
			$Status.text = tr("LOBBY_SERVER_CONNECT")
			$MatchmakeButton.disabled = false
			$MatchmakeButton.visible = true
		STATE_PRE_MATCHMAKING:
			change_state(STATE_MATCHMAKING, matchmake)
		STATE_MATCHMAKING_WAIT:
			if Network.ready_match:
				$Status.text = tr("LOBBY_ROOM_FOUND")
				state = STATE_MATCHMAKING_COMLETE
		STATE_MATCHMAKING_COMLETE:
			change_state(STATE_JOINING, join)
		STATE_START_VOTING:
			change_state(STATE_START_VOTING, setup_voting)
		STATE_MATCH_RECEIVED:
			change_state(STATE_SWITCHING_SCENE, switch_scene)
		_:
			pass


func change_state(new_state: int, state_func: Callable = Callable()):
	state = new_state
	state_func.call()


func reset():
	$Status.text = tr("LOBBY_RESET")
	await Network.reset()
	$LeaveButton.text = tr("LOBBY_BTN_BACK")
	$LeaveButton.visible = true
	$LeaveButton.focus_neighbor_left = "../MatchmakeButton"
	$MatchmakeButton.visible = true
	$MatchmakeButton.grab_focus()
	for child in box_container.get_children():
		child.queue_free()
	$VoteTimeout.stop()
	vote_timeout_started = false
	info_boxes.clear()
	$VoteButton.visible = false
	$UsernameContainer.visible = true
	%UsernameEdit.focus_mode = 2
	state = STATE_INITIAL


func setup():
	$Status.text = tr("LOBBY_SETUP")
	
	var res: bool = await Network.connect_client()
	
	if not res:
		$Status.text = tr("LOBBY_CONNECTION_FAIL")
		state = STATE_INITIAL
		return
	
	var display_name: String = Config.online_username
	if not display_name:
		display_name = await Network.get_display_name()
	if not display_name:
		display_name = "Player" + str(randi_range(100000,999999))
	Config.online_username = display_name
	Config.update_config()
	%UsernameEdit.text = display_name
	
	state = STATE_SETUP_COMPLETE


func matchmake():
	$Status.text = tr("LOBBY_SEARCHING")
	$PingBox.visible = false
	$UsernameContainer.visible = false
	%UsernameEdit.focus_mode = 0
	
	var res: bool = await Network.matchmake(%UsernameEdit.text)
	
	if not res:
		$Status.text = tr("LOBBY_SEARCH_FAIL")
		state = STATE_RESET
		return
	
	state = STATE_MATCHMAKING_WAIT
	return


func join():
	$Status.text = tr("LOBBY_JOINING")
	$PingBox.visible = false
	$UsernameContainer.visible = false
	%UsernameEdit.focus_mode = 0

	if Network.ready_match_type == "race":
		next_course = Network.ready_match_label['course']
		switch_scene()
		state = STATE_SWITCHING_SCENE
		return
	
	var res: bool = await Network.join_match(Network.ready_match)
	
	#Network.socket.received_match_presence.connect(_on_match_presence)
	Network.socket.received_match_state.connect(_on_match_state)
	Network.socket.closed.connect(_on_socket_closed)

	if not res or not Network.cur_match:
		# Disconnect functions
		#Network.socket.received_match_presence.disconnect(_on_match_presence)
		Network.socket.received_match_state.disconnect(_on_match_state)
		Network.socket.closed.disconnect(_on_socket_closed)

		$Status.text = tr("LOBBY_JOIN_FAIL")
		state = STATE_RESET
		return
	
	state = STATE_START_VOTING
	return


func setup_voting():
	$Status.text = tr("LOBBY_VOTING")
	$LeaveButton.text = tr("LOBBY_BTN_LEAVE")
	state = STATE_VOTING
	$VoteButton.disabled = false
	$VoteButton.visible = true
	$LeaveButton.disabled = false
	$LeaveButton.visible = true
	$MatchmakeButton.disabled = true
	$MatchmakeButton.visible = false
	$VoteButton.grab_focus()
	$LeaveButton.focus_neighbor_left = "../VoteButton"
	return


func add_player(username: String, user_id: String):
	if user_id in info_boxes:
		return
	
	var new_box = info_box.instantiate() as LobbyPlayerInfoBox
	new_box.set_username(username)
	if Network.session.user_id == user_id:
		new_box.set_cur_user()
	info_boxes[user_id] = new_box
	box_container.add_child(new_box)


func remove_player(user_id: String):
	if not user_id in info_boxes:
		return
	var cur_box = info_boxes[user_id] as LobbyPlayerInfoBox
	box_container.remove_child(cur_box)
	info_boxes.erase(user_id)
	cur_box.queue_free()


func update_player_name(user_id: String, new_name: String):
	if not user_id in info_boxes:
		return
	info_boxes[user_id].set_username(new_name)


func update_player_pick(user_id: String, pick_text: String):
	if not user_id in info_boxes:
		return
	info_boxes[user_id].set_pick(pick_text)


func _on_matchmake_button_pressed():
	if state == STATE_SETUP_COMPLETE:
		Global.extraPing = $PingBox.value
		$MatchmakeButton.disabled = true
		$MatchmakeButton.visible = false
		$LeaveButton.grab_focus()
		state = STATE_PRE_MATCHMAKING


#func _on_match_presence(p_presence : NakamaRTAPI.MatchPresenceEvent):
	#for p in p_presence.joins:
		#add_player(p.user_id.substr(0, 10), p.user_id)
	#for p in p_presence.leaves:
		#remove_player(p.user_id)

func focus():
	$MatchmakeButton.grab_focus()


func _on_match_state(match_state : NakamaRTAPI.MatchData):
	if Global.extraPing:
		await get_tree().create_timer(Global.get_extra_ping() / 1000.0).timeout
	
	var data: Dictionary = JSON.parse_string(match_state.data)
	match match_state.op_code:
		lobbyOp.SERVER_PING:
			Network.send_match_state(lobbyOp.SERVER_PING, data)
		lobbyOp.SERVER_VOTE_DATA:
			handle_vote_data(data)
		lobbyOp.SERVER_MATCH_DATA:
			#print("Received match data")
			handle_match_data(data)
		lobbyOp.SERVER_ABORT:
			await reload()
		_:
			print("Unknown lobby op code: ", match_state.op_code)


func handle_vote_data(data: Dictionary):
	var presences = data.presences as Dictionary
	var votes = data.votes as Dictionary
	var tick = data.tick as int
	var vote_timeout = data.voteTimeout as int
	var tick_rate = data.tickRate as int
	var ping_data = data.pingData as Dictionary
	var user_data = data.userData as Dictionary
	
	# Setup vote timeout:
	if Network.session.user_id in ping_data:
		var ticks_left = max(vote_timeout - tick, 0)
		var seconds_left = Util.ticks_to_time_with_ping(ticks_left, tick_rate, ping_data[Network.session.user_id])
		if not vote_timeout_started or info_boxes.size() <= 1:
			vote_timeout_started = true
			$VoteTimeout.start(seconds_left)
		elif $VoteTimeout.time_left > 0 and seconds_left < $VoteTimeout.time_left:
			$VoteTimeout.start(seconds_left)
	
	# Update player states
	var cur_user_ids = info_boxes.keys()
	var server_user_ids = presences.keys()
	
	for user_id: String in cur_user_ids:
		if not user_id in server_user_ids:
			remove_player(user_id)
	
	for p in presences.values():
		#print(p.userId, " ", user_data)
		if p.userId in cur_user_ids or !(p.userId in user_data):
			continue
		add_player(user_data[p.userId].displayName, p.userId)
	
	cur_votes = votes
	for user_id in votes:
		var vote_data: Dictionary = votes[user_id]
		update_player_pick(user_id, vote_data['course'])


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
		$Status.text = tr("LOBBY_VOTE_FAIL")
		state = STATE_RESET
		return false
	
	state = STATE_VOTED
	return true


func _on_vote_timeout_timeout():
	$VoteButton.disabled = true
	$VoteButton.visible = false
	$LeaveButton.disabled = true
	$LeaveButton.visible = false
	
	if not cur_vote:
		cur_vote = Util.get_race_courses()[0]
	
	var res = await vote()
	return res


func handle_match_data(data: Dictionary):
	var match_id = data.matchId as String
	var winning_vote = data.winningVote as Dictionary
	var vote_user = data.voteUser as String
	
	$LeaveButton.disabled = true
	$LeaveButton.visible = false
	
	info_boxes[vote_user].set_picked()
	print("Match ID: ", match_id)
	print("Winning vote: ", winning_vote)
	print("Vote user: ", vote_user)

	next_course = winning_vote['course']
	
	Network.ready_match = match_id
	Network.next_match_data = data

	$Status.text = tr("LOBBY_COURSE_SELECT") % winning_vote['course']
	state = STATE_MATCH_RECEIVED


func switch_scene():
	Global.MODE1 = Global.MODE1_ONLINE
	Network.socket.received_match_state.disconnect(_on_match_state)
	Network.socket.closed.disconnect(_on_socket_closed)
	UI.change_scene(Util.get_race_course_path(next_course), true)


func reload():
	await Network.leave_match()
	#await Network.reset()
	#var parent: Node = get_parent()
	#parent.remove_child(self)
	#parent.add_child(load("res://scenes/ui/lobby/lobby.tscn").instantiate())
	#queue_free()
	state = STATE_RESETTING


func _on_leave_button_pressed():
	if state < STATE_MATCHMAKING:
		given_focus = false
		back.emit()
		return
	
	$LeaveButton.visible = false
	await reload()


func _on_socket_closed():
	$Status.text = tr("LOBBY_CONNECTION_LOST")
	reload()

func _gui_input(event: InputEvent) -> void:
	$LeaveButton.grab_focus()
