extends Node

const PORT = 135

@export var oneVersusOne : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	# You can save bandwidth by disabling server relay and peer notifications.
	multiplayer.server_relay = false

func _on_host_pressed():
	# Start as server.
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		return
	multiplayer.multiplayer_peer = peer
	start_game()

func _on_connect_pressed():
	# Start as client.
	var txt : String = $UI/DirectConnect/Options/Remote.text
	if txt == "":
		OS.alert("Need a remote to connect to.")
		return
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(txt, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer
	start_game()

func start_game():
	# Hide the UI and unpause to start the game.
	$UI.hide()
	var game = oneVersusOne.instantiate()
	add_child(game)
	get_tree().paused = false
