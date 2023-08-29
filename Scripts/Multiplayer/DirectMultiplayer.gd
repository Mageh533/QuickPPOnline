extends Node

@export var MainGame : PackedScene

const PORT = 4433

func _ready():
	# Start paused.
	get_tree().paused = true
	$UI/Net/PlayerInfo/Label.hide()
	# You can save bandwidth by disabling server relay and peer notifications.
	multiplayer.server_relay = false
	
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func peer_connected(id):
	$UI/Net/PlayerInfo/Label.visible = true
	$UI/Net/PlayerInfo/Label.text = "2 / 2 Players connected"

func peer_disconnected(id):
	$UI/Net/PlayerInfo/Label.text = "1 / 2 Players connected"

func connected_to_server():
	setSecondPlayerId.rpc_id(1, multiplayer.get_unique_id())
	setUpSeed.rpc_id(1, randi())

@rpc("any_peer", "call_local")
func setUpSeed(seed):
	GameManager.currentSeed = seed
		
	if multiplayer.is_server():
		setUpSeed.rpc_id(GameManager.secondPlayerId, seed)

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
		$UI/Net/PlayerInfo/Label.visible = true
		$UI/Net/PlayerInfo/Label.text = "1 / 2 Players connected"
	multiplayer.multiplayer_peer = peer

func _on_connect_pressed():
	# Start as client.
	var txt : String = $UI/Net/Options/Remote.text
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
	add_child(MainGame.instantiate())
	get_tree().paused = false
	print("Second player is: " + str(GameManager.secondPlayerId))


func _on_start_pressed():
	start_game.rpc()
