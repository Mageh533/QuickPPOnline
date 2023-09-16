extends Node

@export var MainGame : PackedScene

var currentGame
var masterVolumeIndex = AudioServer.get_bus_index("Master")

const PORT = 4433

func _ready(): 
	$Lobby.hide()
	$Browser.hide()
	$UI/SoundPopUp/VSlider.value = db_to_linear(AudioServer.get_bus_volume_db(masterVolumeIndex))
	$UI/OnlinePopUp.hide()
	# You can save bandwidth by disabling server relay and peer notifications.
	multiplayer.server_relay = false
	
	$UI/FadeRect/FadeAnim.play("fadeOut")
	await $UI/FadeRect/FadeAnim.animation_finished
	$UI/FadeRect.hide()

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
	$UI/OnlinePopUp.visible = true

func _on_play_mp_local_pressed():
	start_game()

func _on_sound_button_pressed():
	$UI/SoundPopUp.visible = true

func _on_v_slider_value_changed(value):
	AudioServer.set_bus_volume_db(masterVolumeIndex, linear_to_db(value))

# ==================== Webrtc stuff is below ====================
func _on_find_games_pressed():
	Client.connectToServer("127.0.0.1")
	$Browser.show()

func _on_create_game_pressed():
	Client.connectToServer("127.0.0.1")
	await get_tree().create_timer(1).timeout
	var message = {
		"id" : Client.id,
		"message" : Client.Message.lobby,
		"name" : $UI/OnlinePopUp/VOnlineContainer/UsernameContainer/UsernameInput.text,
		"lobbyValue" : ""
	}
	Client.peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	Client.username = $UI/OnlinePopUp/VOnlineContainer/UsernameContainer/UsernameInput.text
	$Lobby.show()

func _on_join_btn_pressed():
	var message = {
		"id" : Client.id,
		"message" : Client.Message.lobby,
		"name" : $UI/OnlinePopUp/VOnlineContainer/UsernameContainer/UsernameInput.text,
		"lobbyValue" : $Browser/BG/CodeText.text
	}
	Client.peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	Client.username = $UI/OnlinePopUp/VOnlineContainer/UsernameContainer/UsernameInput.text
	$Lobby.show()

func _on_dev_server_pressed():
	Server.startServer()

func _on_lobby_player_ready():
	if GameManager.Players.size() == GameManager.readyRTCPlayers.size():
		start_game()
