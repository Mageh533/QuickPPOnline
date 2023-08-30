extends Node

@export var MainGame : PackedScene

var currentGame
var masterVolumeIndex = AudioServer.get_bus_index("Master")

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket
var username = "Unknown"

const PORT = 4433

func _ready():
	# Start paused.
	get_tree().paused = true
	if OS.get_name() == "Web":
		$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet.hide()
	$UI/SoundPopUp/VSlider.value = db_to_linear(AudioServer.get_bus_volume_db(masterVolumeIndex))
	$UI/MenuItems/OnlinePopUp.hide()
	$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo.hide()
	# You can save bandwidth by disabling server relay and peer notifications.
	multiplayer.server_relay = false
	
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
	$UI/FadeRect/FadeAnim.play("fadeOut")
	await $UI/FadeRect/FadeAnim.animation_finished
	$UI/FadeRect.hide()

func ConnectToNakama():
	client = Nakama.create_client('defaultkey', "127.0.0.1", 7350,
	"http", 3, NakamaLogger.LOG_LEVEL.ERROR)
	
	var id = OS.get_unique_id()
	session = await client.authenticate_device_async(id, username)
	if session.is_exception():
		print("Connection to server has failed!")
		return
		
	socket = Nakama.create_socket_from(client)
	await socket.connect_async(session)
	
	print("Connected To server")

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
@rpc("any_peer", "call_local")
func setUpSeed(seedShare):
	GameManager.currentSeed = seedShare
		
	if multiplayer.is_server():
		setUpSeed.rpc_id(GameManager.secondPlayerId, seedShare)

# Since this is only a 1v1 where one player is the server, we only need to know the id of player 2
@rpc("any_peer", "call_local")
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

@rpc("any_peer", "call_local")
func start_game():
	# Hide the UI and unpause to start the game.
	$UI.hide()
	currentGame = MainGame.instantiate()
	currentGame.restartPressed.connect(on_restart_pressed)
	$GameContainer.add_child(currentGame)
	get_tree().paused = false
	print("Second player is: " + str(GameManager.secondPlayerId))

@rpc("any_peer", "call_local")
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
