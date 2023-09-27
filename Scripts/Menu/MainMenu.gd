extends Node

@export var SoloGame : PackedScene
@export var MainGame : PackedScene

var currentGame
var masterVolumeIndex = AudioServer.get_bus_index("Master")

const PORT = 4433

func _ready():
	$PermaUI/PausedPanel.hide()
	if OS.get_name() == "Web":
		$UI/MenuItems/PlayMPOnline.disabled = true
	$PermaUI/SoundPopUp/VSlider.value = db_to_linear(AudioServer.get_bus_volume_db(masterVolumeIndex))
	$UI/MenuItems/OnlinePopUp.hide()
	$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo.hide()
	# You can save bandwidth by disabling server relay and peer notifications.
	multiplayer.server_relay = false
	
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
	playFadeAnims("fadeOut")

func _process(delta):
	$PermaUI/FPSCounter.text = "FPS: " + str(Engine.get_frames_per_second())
	if !GameManager.onlineMatch:
		if $PermaUI/SettingsPopUp.visible == true:
			get_tree().paused = true
	if get_tree().paused and $GameContainer.get_child_count() > 0:
		$PermaUI/PausedPanel.show()
	else:
		$PermaUI/PausedPanel.hide()

func _on_settings_pop_up_popup_hide():
	get_tree().paused = false

func _on_play_mp_local_pressed():
	setUpLocalGame()
	await playFadeAnims("fadeIn")
	start_game()

func _on_play_solo_pressed():
	setUpLocalGame()
	await playFadeAnims("fadeIn")
	currentGame = SoloGame.instantiate()
	currentGame.gameEnd.connect(on_game_end)
	$GameContainer.add_child(currentGame)
	await playFadeAnims("fadeOut")
	get_tree().paused = false


func on_restart_pressed():
	await playFadeAnims("fadeIn")
	randomize()
	GameManager.currentSeed = randi()
	restartGame.rpc()

func on_game_end():
	$PermaUI/ReturnButton.show()

func _on_sound_button_pressed():
	$PermaUI/SoundPopUp.show()

func _on_settings_button_pressed():
	$PermaUI/SettingsPopUp.show()

func _on_v_slider_value_changed(value):
	AudioServer.set_bus_volume_db(masterVolumeIndex, linear_to_db(value))

func _on_return_button_pressed():
	await playFadeAnims("fadeIn")
	get_tree().reload_current_scene()

func playFadeAnims(anim):
	$PermaUI/FadeRect.show()
	$PermaUI/FadeRect/FadeAnim.play(anim)
	await $PermaUI/FadeRect/FadeAnim.animation_finished
	$PermaUI/FadeRect.hide()

func setUpLocalGame():
	randomize()
	GameManager.currentSeed = randi()
	$PermaUI/SettingsPopUp/VBoxContainer/Controls.disabled = true

# ======================== Online related ========================

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

func _on_play_mp_online_mouse_entered():
	if OS.get_name() == "Web":
		$UI/OnlineWarning.show()

func _on_play_mp_online_mouse_exited():
	if OS.get_name() == "Web":
		$UI/OnlineWarning.hide()

func _on_start_pressed():
	GameManager.onlineMatch = true
	start_game.rpc()

func _on_play_mp_online_pressed():
	$UI/MenuItems/OnlinePopUp.visible = true

@rpc("any_peer", "call_local")
func start_game():
	# Hide the UI and unpause to start the game.
	$UI.hide()
	currentGame = MainGame.instantiate()
	currentGame.restartGame.connect(on_restart_pressed)
	currentGame.gameEnd.connect(on_game_end)
	$GameContainer.add_child(currentGame)
	await playFadeAnims("fadeOut")
	get_tree().paused = false
	print("Second player is: " + str(GameManager.secondPlayerId))

@rpc("any_peer", "call_local")
func restartGame():
	currentGame.queue_free()
	start_game()

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


# Since this is only a 1v1 where one player is the server, we only need to know the id of player 2
@rpc("any_peer", "call_local")
func setSecondPlayerId(id):
	if GameManager.secondPlayerId == 0:
		GameManager.secondPlayerId = id
		
	if multiplayer.is_server():
		setSecondPlayerId.rpc_id(id, id)

func peer_connected(_id):
	$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo.visible = true
	$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Start.disabled = false
	$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Label.text = "2 / 2 Players connected"

func peer_disconnected(_id):
	$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Start.disabled = true
	$UI/MenuItems/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Label.text = "1 / 2 Players connected"

func connection_failed():
	pass
