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

@rpc("any_peer", "call_local")
func start_game():
	# Hide the UI and unpause to start the game.
	$UI.hide()
	currentGame = MainGame.instantiate()
	currentGame.restartPressed.connect(on_restart_pressed)
	$GameContainer.add_child(currentGame)
	get_tree().paused = false

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
	$UI/OnlinePopUp.hide()

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
	$UI/OnlinePopUp.hide()

func _on_lobby_player_ready():
	if GameManager.Players.size() == GameManager.readyRTCPlayers.size():
		start_game()
