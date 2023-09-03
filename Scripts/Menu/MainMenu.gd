extends Node

@export var MainGame : PackedScene
@export var ReadyUser: PackedScene

var currentGame
var masterVolumeIndex = AudioServer.get_bus_index("Master")

var client : NakamaClient
var session : NakamaSession
var socket : NakamaSocket
var username = ""
var email = ""
var password = ""
var Players = {}
var ReadyPlayers = []

const PORT = 4433

func _ready():
	# Start paused.
	get_tree().paused = true
	if OS.get_name() == "Web":
		$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet.hide()
	else:
		$UI/MenuItems/OnlinePopUp/VOnlineContainer/HUserContainer2/EmailInput.hide()
		$UI/MenuItems/OnlinePopUp/VOnlineContainer/HUserContainer3/PasswordInput.hide()
		$UI/MenuItems/OnlinePopUp/VOnlineContainer/HUserContainer2.hide()
		$UI/MenuItems/OnlinePopUp/VOnlineContainer/HUserContainer3.hide()
	$UI/SoundPopUp/VSlider.value = db_to_linear(AudioServer.get_bus_volume_db(masterVolumeIndex))
	$UI/MenuItems/OnlinePopUp.hide()
	$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo.hide()
	# You can save bandwidth by disabling server relay and peer notifications.
	# multiplayer.server_relay = false
	
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
	$UI/FadeRect/FadeAnim.play("fadeOut")
	$UI/FadeRect.hide()
	$UI/MatchLobby.hide()
	await $UI/FadeRect/FadeAnim.animation_finished

func ConnectToNamaka():
	client = Nakama.create_client('defaultkey', "204.48.28.159", 7350, 
	'http', 10, NakamaLogger.LOG_LEVEL.ERROR)
	
	if OS.get_name() == "Web":
		session = await client.authenticate_email_async(email, password, username)
	else:
		var id = OS.get_unique_id()
		session = await client.authenticate_device_async(id, username)
	if session.is_exception():
		print("Connection to server has failed with code: " + str(session.exception))
		return
		
	socket = Nakama.create_socket_from(client)
	await socket.connect_async(session)
	
	print("Successfully connected to server")
	
	StartMatchMaking()

func StartMatchMaking():
	OnlineMatch.min_players = 2
	OnlineMatch.min_players = 2
	OnlineMatch.client_version = 'dev'
	OnlineMatch.use_network_relay = OnlineMatch.NetworkRelay.AUTO
	
	OnlineMatch.disconnected.connect(onOnlineMatchDisconnected)
	OnlineMatch.error.connect(onOnlineMatchError)
	OnlineMatch.match_created.connect(onOnlineMatchCreated)
	OnlineMatch.match_joined.connect(onOnlineMatchJoined)
	OnlineMatch.matchmaker_matched.connect(onOnlineMatchMatchmakerMatched)
	OnlineMatch.player_joined.connect(onOnlineMatchPlayerJoined)
	OnlineMatch.player_left.connect(onOnlineMatchPlayerLeft)
	OnlineMatch.player_status_changed.connect(onOnlineMatchPlayerStatusChanged)
	OnlineMatch.match_ready.connect(onOnlineMatchReady)
	OnlineMatch.match_not_ready.connect(onOnlineMatchNotReady)
	
	OnlineMatch.start_matchmaking(socket)
	print("Matchmaking started...")

func onOnlineMatchDisconnected():
	pass

func onOnlineMatchError(errorMessage):
	print(errorMessage)

func onOnlineMatchCreated():
	pass

func onOnlineMatchJoined(player):
	print(player)

func onOnlineMatchMatchmakerMatched(_players):
	$UI/MatchLobby/Panel/RichTextLabel.text = "Player Found"

func onOnlineMatchPlayerJoined(player):
	print(player)

func onOnlineMatchPlayerLeft():
	pass

func onOnlineMatchPlayerStatusChanged(player, status):
	print(player, status)

func onOnlineMatchReady(players):
	$UI/MatchLobby/Panel/RichTextLabel.text = "Match is ready"
	Players = players
	$UI/MatchLobby/Panel/ReadyBTN.disabled = false
	for player in players.values():
		var readyUser = ReadyUser.instantiate()
		readyUser.name = player.session_id
		readyUser.setUsername(player.username)
		$UI/MatchLobby/Panel/PlayerList.add_child(readyUser)

func onOnlineMatchNotReady():
	pass

func peer_connected(_id):
	$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo.visible = true
	$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Start.disabled = false
	$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Label.text = "2 / 2 Players connected"

func peer_disconnected(_id):
	$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Start.disabled = true
	$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Label.text = "1 / 2 Players connected"

func connected_to_server():
	setSecondPlayerId.rpc_id(1, multiplayer.get_unique_id())
	randomize()
	setUpSeed.rpc_id(1, randi())

# Make sure both players have the same seed
@rpc("any_peer", "call_local", "reliable")
func setUpSeed(seedShare):
	GameManager.currentSeed = seedShare
		
	if multiplayer.is_server():
		setUpSeed.rpc_id(GameManager.secondPlayerId, seedShare)

# Since this is only a 1v1 where one player is the server, we only need to know the id of player 2
@rpc("any_peer", "call_local", "reliable")
func setSecondPlayerId(id):
	if GameManager.secondPlayerId == 0:
		GameManager.secondPlayerId = id
		
	if multiplayer.is_server():
		setSecondPlayerId.rpc_id(id, id)

func connection_failed():
	pass

func _on_host_pressed():
	# Start as server.
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		return
	else:
		$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo.visible = true
		$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Start.disabled = true
		$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Label.text = "1 / 2 Players connected"
	multiplayer.multiplayer_peer = peer

func _on_connect_pressed():
	# Start as client.
	var txt : String = $UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/Options/Remote.text
	if txt == "":
		OS.alert("Need a remote to connect to.")
		return
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(txt, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer

@rpc("any_peer", "call_local", "reliable")
func start_game():
	# Hide the UI and unpause to start the game.
	$UI.hide()
	currentGame = MainGame.instantiate()
	currentGame.restartPressed.connect(on_restart_pressed)
	$GameContainer.add_child(currentGame)
	get_tree().paused = false
	print("Second player is: " + str(GameManager.secondPlayerId))

@rpc("any_peer", "call_local", "reliable")
func restartGame():
	currentGame.queue_free()
	currentGame = MainGame.instantiate()
	$GameContainer.add_child(currentGame)

func on_restart_pressed():
	restartGame.rpc()

func _on_start_pressed():
	start_game.rpc()

func _on_play_mp_online_pressed():
	$UI/MenuItems/OnlinePopUp.visible = true

func _on_play_mp_local_pressed():
	start_game()

func _on_sound_button_pressed():
	$UI/SoundPopUp.visible = true

func _on_v_slider_value_changed(value):
	AudioServer.set_bus_volume_db(masterVolumeIndex, linear_to_db(value))

func _on_quick_play_pressed():
	username = $UI/MenuItems/OnlinePopUp/VOnlineContainer/HUserContainer/UsernameInput.text
	email = $UI/MenuItems/OnlinePopUp/VOnlineContainer/HUserContainer2/EmailInput.text
	password = $UI/MenuItems/OnlinePopUp/VOnlineContainer/HUserContainer3/PasswordInput.text
	ConnectToNamaka()
	$UI/MenuItems/OnlinePopUp.hide()
	$UI/MatchLobby.visible = true

@rpc("any_peer", "call_local", "reliable")
func setAsReady(id):
	$UI/MatchLobby/Panel/PlayerList.get_node_or_null(id).setReadyStatus("Ready")
	ReadyPlayers.append(id)
	if ReadyPlayers.size() == Players.size():
		print("All players are ready")
		$UI/MatchLobby/Panel/RichTextLabel.text = "Starting Game..."
		await get_tree().create_timer(1).timeout
		GameManager.nakamaMatch = true
		start_game()

func _on_ready_btn_pressed():
	setAsReady.rpc(OnlineMatch.get_my_session_id())
