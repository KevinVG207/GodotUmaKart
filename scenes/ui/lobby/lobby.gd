extends Control

const STATE_IDLE = -99
const STATE_RESET = -2
const STATE_RESETTING = -1
const STATE_INITIAL = 0
const STATE_SETUP = 1
const STATE_SETUP_2 = -10
const STATE_SETUP_3 = -11
const STATE_SETUP_COMPLETE = 2
const STATE_PRE_MATCHMAKING = -3
const STATE_PRE_MATCHMAKING_2 = -4
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

var next_course = ""
var given_focus := false

signal back

@export var info_box: PackedScene
var info_boxes: Dictionary[int, LobbyPlayerInfoBox] = {}
@onready var box_container: GridContainer = %PlayerInfoContainer


func _ready():
	state = STATE_IDLE
	if Network.our_room:
		state = STATE_MATCHMAKING_COMLETE
	Global.goto_lobby_screen.connect(start)
	Network.connection_success.connect(setup_complete)
	Network.connection_failed.connect(setup_failed)
	Network.initialization_success.connect(player_initialized)
	RPCClient.player_left_room_received.connect(_on_player_disconnect)


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
			change_state(STATE_PRE_MATCHMAKING_2, initialize_player)
		STATE_MATCHMAKING_WAIT:
			if Network.our_room:
				$Status.text = tr("LOBBY_ROOM_FOUND")
				state = STATE_MATCHMAKING_COMLETE
		STATE_MATCHMAKING_COMLETE:
			change_state(STATE_JOINING, join)
		STATE_START_VOTING:
			change_state(STATE_START_VOTING, setup_voting)
		STATE_VOTING, STATE_VOTED:
			update_votes()
		STATE_MATCH_RECEIVED:
			change_state(STATE_SWITCHING_SCENE, switch_scene)
		_:
			pass


func change_state(new_state: int, state_func: Callable = Callable()):
	state = new_state
	state_func.call()


func reset():
	Global.final_lobby = null
	$Status.text = tr("LOBBY_RESET")
	Network.reset()
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
	var display_name: String = Config.online_username
	if not display_name:
		display_name = Network.our_player.username
	if not display_name:
		display_name = "Player" + str(randi_range(100000,999999))
	Config.online_username = display_name
	Config.update_config()
	%UsernameEdit.text = display_name
	next_course = ""
	state = STATE_INITIAL


func setup():
	$Status.text = tr("LOBBY_SETUP")
	state = STATE_SETUP_2
	Network.setup()

func setup_complete():
	state = STATE_SETUP_COMPLETE

func setup_failed():
	$Status.text = tr("LOBBY_CONNECTION_FAIL")
	state = STATE_INITIAL
	return

func initialize_player() -> void:
	state = STATE_MATCHMAKING
	Network.our_username = Config.online_username
	Network.initialize_player()

func player_initialized() -> void:
	matchmake()

func matchmake():
	$Status.text = tr("LOBBY_SEARCHING")
	$PingBox.visible = false
	$UsernameContainer.visible = false
	%UsernameEdit.focus_mode = 0
	Network.join_random_room()
	
	state = STATE_MATCHMAKING_WAIT
	return


func join():
	$Status.text = tr("LOBBY_JOINING")
	$PingBox.visible = false
	$UsernameContainer.visible = false
	%UsernameEdit.focus_mode = 0
	
	if not Network.our_room:
		# Disconnect functions
		$Status.text = tr("LOBBY_JOIN_FAIL")
		state = STATE_INITIAL
		return

	if Network.our_room.type == DomainRoom.RoomType.RACE:
		var race = Network.our_room as DomainRoom.Race
		next_course = race.course_name
		switch_scene()
		state = STATE_SWITCHING_SCENE
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


func add_player(player: DomainPlayer.Player):
	if player.peer_id in info_boxes:
		return
	
	var new_box = info_box.instantiate() as LobbyPlayerInfoBox
	new_box.set_username(player.username)
	if Network.peer_id == player.peer_id:
		new_box.set_cur_user()
	info_boxes[player.peer_id] = new_box
	box_container.add_child(new_box)


func remove_player(user_id: int):
	if not user_id in info_boxes:
		return
	var cur_box = info_boxes[user_id] as LobbyPlayerInfoBox
	box_container.remove_child(cur_box)
	info_boxes.erase(user_id)
	cur_box.queue_free()


func update_player_name(player: DomainPlayer.Player):
	if not player.peer_id in info_boxes:
		return
	info_boxes[player.peer_id].set_username(player.username)


func update_player_pick(user_id: int, pick_text: String):
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


func focus():
	$MatchmakeButton.grab_focus()

func _on_player_disconnect(player: DomainPlayer.Player, is_transfer: bool) -> void:
	if is_transfer:
		return
	remove_player(player.peer_id)

func update_votes() -> void:
	var lobby: DomainRoom.Lobby
	if not Network.our_room:
		reset()
		return
	if Network.our_room.type == DomainRoom.RoomType.RACE:
		if !Global.final_lobby:
			return
		print("RECEIVED RACE ROOM")
		state = STATE_MATCH_RECEIVED
		lobby = Global.final_lobby
	else:
		lobby = Network.our_room as DomainRoom.Lobby
	
	# Setup vote timeout:
	var ticks_left = max(lobby.voting_timeout - lobby.tick, 0)
	var seconds_left = Util.ticks_to_time_with_ping(ticks_left, lobby.tick_rate, lobby.players[Network.peer_id].ping)
	if not vote_timeout_started or info_boxes.size() <= 1:
		vote_timeout_started = true
		$VoteTimeout.start(seconds_left)
	elif $VoteTimeout.time_left > 0 and seconds_left < $VoteTimeout.time_left:
		$VoteTimeout.start(seconds_left)
	
	# Update player states
	var cur_user_ids := info_boxes.keys()
	var server_user_ids := lobby.players.keys()
	#
	#for user_id in cur_user_ids:
		#if not user_id in server_user_ids:
			#remove_player(user_id)
	
	for p in lobby.players.values():
		if p.peer_id in cur_user_ids:
			continue
		add_player(p)
	
	for user_id in lobby.votes:
		var vote_data := lobby.votes[user_id]
		update_player_pick(user_id, vote_data.course_name)
	
	# Handle winning vote
	if !lobby.winning_vote:
		return
	if next_course:
		return
	$LeaveButton.disabled = true
	$LeaveButton.visible = false
	
	info_boxes[lobby.winning_vote].set_picked()
	var vote_data := lobby.votes[lobby.winning_vote]
	print("Winning course: ", vote_data.course_name)
	print("Vote user: ", lobby.winning_vote)
	$Status.text = tr("LOBBY_COURSE_SELECT") % vote_data.course_name

	next_course = vote_data.course_name


func _on_vote_button_pressed():
	$VoteButton.disabled = true
	$VoteButton.visible = false

	vote()


func vote():
	var data := DomainRoom.VoteData.new()
	data.course_name = Util.get_race_courses()[0]
	RPCServer.send_vote.rpc_id(1, data.serialize())
	print("VOTE SENT")
	state = STATE_VOTED
	return true


func _on_vote_timeout_timeout():
	if next_course:
		return
	
	$VoteButton.disabled = true
	$VoteButton.visible = false
	$LeaveButton.disabled = true
	$LeaveButton.visible = false
	
	vote()

func switch_scene():
	Global.MODE1 = Global.MODE1_ONLINE
	UI.change_scene(Util.get_race_course_path(next_course), true)


func reload():
	Network.reset()
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
