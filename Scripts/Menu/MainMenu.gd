extends Node

@export var SoloGames : Array[PackedScene]
@export var MainGame : PackedScene

var currentGame
var masterVolumeIndex = AudioServer.get_bus_index("Master")

enum MenuSets {
	MAIN_MENU,
	SOLO_MENU,
	SOLO_PREGAME,
	MULTIPLAYER_MENU,
	SETTINGS_MENU,
	MULTIPLAYER_LOCAL_MENU,
	MULTIPLAYER_LOCAL_PREGAME,
	MULTIPLAYER_ONLINE_MENU
}

var currentMenu = MenuSets.MAIN_MENU

const PORT = 4433

func _ready():
	$PermaUI/PauseButton.hide()
	get_tree().paused = false
	menuStartAnims()
	$PermaUI/PausedPanel.hide()
	$PermaUI/TouchScreenControls.hide()
	$PermaUI/SoundPopUp/VSlider.value = db_to_linear(AudioServer.get_bus_volume_db(masterVolumeIndex))
	# You can save bandwidth by disabling server relay and peer notifications.
	multiplayer.server_relay = false
	
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func _process(_delta):
	if GameManager.clientSettings.fpsCounter == true:
		$PermaUI/FPSCounter.show()
		$PermaUI/FPSCounter.text = "FPS: " + str(Engine.get_frames_per_second())
	else:
		$PermaUI/FPSCounter.hide()
	
	if !GameManager.onlineMatch:
		if $PermaUI/SettingsPopUp.visible == true:
			get_tree().paused = true
	if get_tree().paused and $GameContainer.get_child_count() > 0:
		$PermaUI/PausedPanel.show()
	else:
		$PermaUI/PausedPanel.hide()
	
	if currentMenu == MenuSets.MAIN_MENU:
		if $UI/BackButton.modulate.a == 1:
			get_tree().create_tween().tween_property($UI/BackButton, "modulate:a", 0, 0.2)
	else:
		if $UI/BackButton.modulate.a == 0:
			get_tree().create_tween().tween_property($UI/BackButton, "modulate:a", 1, 0.2)

func startSoloGame(Game : int):
	setUpLocalGame()
	await playFadeAnims("fadeIn")
	$UI.hide()
	currentGame = SoloGames[Game].instantiate()
	currentGame.gameEnd.connect(on_game_end)
	$GameContainer.add_child(currentGame)
	await playFadeAnims("fadeOut")
	get_tree().paused = false
	$PermaUI/TouchScreenControls.show()

func startLocalMpGame():
	setUpLocalGame()
	await playFadeAnims("fadeIn")
	start_game()

func on_restart_pressed():
	await playFadeAnims("fadeIn")
	randomize()
	GameManager.currentSeed = randi()
	restartGame.rpc()

func on_game_end():
	$PermaUI/ReturnButton.show()

func _on_sound_button_pressed():
	$PermaUI/SoundPopUp.show()

func _on_pause_button_pressed():
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
	$PermaUI/PauseButton.show()
	randomize()
	GameManager.currentSeed = randi()

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

func _on_start_pressed():
	GameManager.onlineMatch = true
	start_game.rpc()

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
	$PermaUI/TouchScreenControls.show()

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
		$UI/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo.visible = true
		$UI/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Start.disabled = true
		$UI/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Label.text = "1 / 2 Players connected"
	multiplayer.multiplayer_peer = peer

func _on_connect_pressed():
	# Start as client.
	var txt : String = $UI/OnlinePopUp/VOnlineContainer/DirectNet/Options/Remote.text
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
# But this essentially sucks and needs to be rewritten to work with more than 2 players
@rpc("any_peer", "call_local")
func setSecondPlayerId(id):
	if GameManager.secondPlayerId == 0:
		GameManager.secondPlayerId = id
		
	if multiplayer.is_server():
		setSecondPlayerId.rpc_id(id, id)

func peer_connected(_id):
	$UI/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo.visible = true
	$UI/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Start.disabled = false
	$UI/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Label.text = "2 / 2 Players connected"

func peer_disconnected(_id):
	$UI/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Start.disabled = true
	$UI/OnlinePopUp/VOnlineContainer/DirectNet/PlayerInfo/Label.text = "1 / 2 Players connected"

func connection_failed():
	pass

# ======== Settings stuff ========
func _on_return_to_menu_pressed():
	get_tree().reload_current_scene()

func _on_check_box_toggled(button_pressed):
	GameManager.generalSettings.fpsCounter = button_pressed

# Pause game when settings menu is open
func _on_settings_pop_up_popup_hide():
	get_tree().paused = false

# ======== UI Menus animations ========
func menuStartAnims():
	$UI/Background.modulate.a = 0
	await get_tree().create_timer(0.01).timeout
	$UI/MenuItems/PlaySolo.position.x = 1200
	$UI/MenuItems/PlayMP.position.x = -1200
	$UI/MenuItems/MenuSettings.position.x = 1200
	await get_tree().create_timer(1).timeout
	var tween = get_tree().create_tween()
	var tween2 = get_tree().create_tween()
	tween2.tween_property($UI/Background, "modulate:a", 1, 2)
	tween2.tween_property($UI/EAWarning, "modulate:a", 1, 1)
	tween.tween_property($UI/MenuItems/PlaySolo, "position:x", 400, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($UI/MenuItems/PlayMP, "position:x", -400, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($UI/MenuItems/MenuSettings, "position:x", 400, 0.3).set_trans(Tween.TRANS_CUBIC)

func mainMenuHide():
	var tween = get_tree().create_tween()
	get_tree().create_tween().tween_property($UI/MenuItems/PlaySolo, "position:x", 1200, 0.3).set_trans(Tween.TRANS_CUBIC)
	get_tree().create_tween().tween_property($UI/MenuItems/PlayMP, "position:x", -1200, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($UI/MenuItems/MenuSettings, "position:x", 1200, 0.3).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	$UI/MenuItems.hide()

func mainMenuShow():
	$UI/MenuItems.modulate.a = 0
	$UI/MenuItems/PlaySolo.position.x = 1200
	$UI/MenuItems/PlayMP.position.x = -1200
	$UI/MenuItems/MenuSettings.position.x = 1200
	await get_tree().create_timer(0.2).timeout
	$UI/MenuItems.show()
	get_tree().create_tween().tween_property($UI/MenuItems, "modulate:a", 1, 0.3) # Weird workaround to stop flickering when switching menus
	get_tree().create_tween().tween_property($UI/MenuItems/PlaySolo, "position:x", 400, 0.3).set_trans(Tween.TRANS_CUBIC)
	get_tree().create_tween().tween_property($UI/MenuItems/PlayMP, "position:x", -400, 0.3).set_trans(Tween.TRANS_CUBIC)
	get_tree().create_tween().tween_property($UI/MenuItems/MenuSettings, "position:x", 400, 0.3).set_trans(Tween.TRANS_CUBIC)

func soloMenuShow():
	$UI/SoloMenu.modulate.a = 0
	$UI/SoloMenu/Endless.position.x = 1200
	$UI/SoloMenu/TinyPuyo.position.x = 1200
	$UI/SoloMenu/Fever.position.x = 1200
	await get_tree().create_timer(0.2).timeout
	$UI/SoloMenu.show()
	get_tree().create_tween().tween_property($UI/SoloMenu, "modulate:a", 1, 0.3)
	get_tree().create_tween().tween_property($UI/SoloMenu/Endless, "position:x", 400, 0.3).set_trans(Tween.TRANS_CUBIC)
	get_tree().create_tween().tween_property($UI/SoloMenu/TinyPuyo, "position:x", 400, 0.3).set_trans(Tween.TRANS_CUBIC)
	get_tree().create_tween().tween_property($UI/SoloMenu/Fever, "position:x", 400, 0.3).set_trans(Tween.TRANS_CUBIC)

func soloMenuHide():
	var tween = get_tree().create_tween()
	get_tree().create_tween().tween_property($UI/SoloMenu/Endless, "position:x", 1200, 0.3).set_trans(Tween.TRANS_CUBIC)
	get_tree().create_tween().tween_property($UI/SoloMenu/TinyPuyo, "position:x", 1200, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($UI/SoloMenu/Fever, "position:x", 1200, 0.3).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	$UI/SoloMenu.hide()

func mPMenuShow():
	$UI/MultiplayerMenu.modulate.a = 0
	$UI/MultiplayerMenu/LocalMP.position.x = -1200
	$UI/MultiplayerMenu/OnlineMP.position.x = -1200
	await get_tree().create_timer(0.2).timeout
	$UI/MultiplayerMenu.show()
	get_tree().create_tween().tween_property($UI/MultiplayerMenu, "modulate:a", 1, 0.3)
	get_tree().create_tween().tween_property($UI/MultiplayerMenu/LocalMP, "position:x", -400, 0.3).set_trans(Tween.TRANS_CUBIC)
	get_tree().create_tween().tween_property($UI/MultiplayerMenu/OnlineMP, "position:x", -400, 0.3).set_trans(Tween.TRANS_CUBIC)

func mPMenuHide():
	var tween = get_tree().create_tween()
	get_tree().create_tween().tween_property($UI/MultiplayerMenu/LocalMP, "position:x", -1200, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($UI/MultiplayerMenu/OnlineMP, "position:x", -1200, 0.3).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	$UI/MultiplayerMenu.hide()

func localMpMenuShow():
	$UI/LocalMPScroll.modulate.a = 0
	$UI/LocalMPScroll.position.x = -2400
	await get_tree().create_timer(0.2).timeout
	$UI/LocalMPScroll.show()
	get_tree().create_tween().tween_property($UI/LocalMPScroll, "modulate:a", 1, 0.3)
	get_tree().create_tween().tween_property($UI/LocalMPScroll, "position:x", 0, 0.3).set_trans(Tween.TRANS_CUBIC)

func localMpMenuHide():
	var tween = get_tree().create_tween()
	tween.tween_property($UI/LocalMPScroll, "position:x", -1200, 0.3).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	$UI/LocalMPScroll.hide()

func settingsMenuShow():
	$UI/SettingsPanel.position.x = 1200
	$UI/SettingsPanel.show()
	get_tree().create_tween().tween_property($UI/SettingsPanel, "position:x", 250, 0.3)

func settingsMenuHide():
	var tween = get_tree().create_tween()
	tween.tween_property($UI/SettingsPanel, "position:x", 1200, 0.3)
	await tween.finished
	$UI/SettingsPanel.hide()

func soloOptionsShow():
	if !$UI/SoloOptionsPanel.visible:
		$UI/SoloOptionsPanel.modulate.a = 0
		$UI/SoloOptionsPanel.show()
		get_tree().create_tween().tween_property($UI/SoloOptionsPanel, "modulate:a", 1, 0.3)

func soloOptionsHide():
	var tween = get_tree().create_tween()
	tween.tween_property($UI/SoloOptionsPanel, "modulate:a", 0, 0.3)
	await tween.finished
	$UI/SoloOptionsPanel.hide()

func mpOptionsShow():
	if !$UI/MultiplayerOptionsPanel.visible:
		$UI/MultiplayerOptionsPanel.modulate.a = 0
		$UI/MultiplayerOptionsPanel.show()
		get_tree().create_tween().tween_property($UI/MultiplayerOptionsPanel, "modulate:a", 1, 0.3)

func mpOptionsHide():
	var tween = get_tree().create_tween()
	tween.tween_property($UI/MultiplayerOptionsPanel, "modulate:a", 0, 0.3)
	await tween.finished
	$UI/MultiplayerOptionsPanel.hide()

# ======== UI Buttons animations ========
# ======== Main Menu Buttons ========
func _on_play_solo_mouse_entered():
	if currentMenu == MenuSets.MAIN_MENU:
		get_tree().create_tween().tween_property($UI/MenuItems/PlaySolo, "position:x", 350, 0.1)

func _on_play_solo_mouse_exited():
	if currentMenu == MenuSets.MAIN_MENU:
		get_tree().create_tween().tween_property($UI/MenuItems/PlaySolo, "position:x", 400, 0.1)

func _on_play_mp_local_mouse_entered():
	if currentMenu == MenuSets.MAIN_MENU:
		get_tree().create_tween().tween_property($UI/MenuItems/PlayMP, "position:x", -350, 0.1)

func _on_play_mp_local_mouse_exited():
	if currentMenu == MenuSets.MAIN_MENU:
		get_tree().create_tween().tween_property($UI/MenuItems/PlayMP, "position:x", -400, 0.1)

func _on_menu_settings_mouse_entered():
	if currentMenu == MenuSets.MAIN_MENU:
		get_tree().create_tween().tween_property($UI/MenuItems/MenuSettings, "position:x", 350, 0.1)

func _on_menu_settings_mouse_exited():
	if currentMenu == MenuSets.MAIN_MENU:
		get_tree().create_tween().tween_property($UI/MenuItems/MenuSettings, "position:x", 400, 0.1)

func _on_menu_settings_pressed():
	currentMenu = MenuSets.SETTINGS_MENU
	await mainMenuHide()
	await settingsMenuShow()

func _on_play_solo_pressed():
	currentMenu = MenuSets.SOLO_MENU
	await mainMenuHide()
	await soloMenuShow()

func _on_play_mp_pressed():
	currentMenu = MenuSets.MULTIPLAYER_MENU
	await mainMenuHide()
	await mPMenuShow()

# ======== Solo Menu Buttons ========
func _on_classic_mouse_entered():
	if currentMenu == MenuSets.SOLO_MENU:
		get_tree().create_tween().tween_property($UI/SoloMenu/Endless, "position:x", 350, 0.1)

func _on_classic_mouse_exited():
	if currentMenu == MenuSets.SOLO_MENU:
		get_tree().create_tween().tween_property($UI/SoloMenu/Endless, "position:x", 400, 0.1)

func _on_tiny_puyo_mouse_entered():
	if currentMenu == MenuSets.SOLO_MENU:
		get_tree().create_tween().tween_property($UI/SoloMenu/TinyPuyo, "position:x", 350, 0.1)

func _on_tiny_puyo_mouse_exited():
	if currentMenu == MenuSets.SOLO_MENU:
		get_tree().create_tween().tween_property($UI/SoloMenu/TinyPuyo, "position:x", 400, 0.1)

func _on_tiny_puyo_pressed():
	GameManager.soloMatchSettings.gamemode = "Endless Tiny Puyo"
	currentMenu = MenuSets.SOLO_PREGAME
	await soloMenuHide()
	await soloOptionsShow()

func _on_endless_pressed():
	GameManager.soloMatchSettings.gamemode = "Endless"
	currentMenu = MenuSets.SOLO_PREGAME
	await soloMenuHide()
	await soloOptionsShow()

# ======== Multiplayer Menu Buttons ========
func _on_local_mp_mouse_entered():
	if currentMenu == MenuSets.MULTIPLAYER_MENU:
		get_tree().create_tween().tween_property($UI/MultiplayerMenu/LocalMP, "position:x", -350, 0.1)

func _on_local_mp_mouse_exited():
	if currentMenu == MenuSets.MULTIPLAYER_MENU:
		get_tree().create_tween().tween_property($UI/MultiplayerMenu/LocalMP, "position:x", -400, 0.1)

func _on_local_mp_pressed():
	currentMenu = MenuSets.MULTIPLAYER_LOCAL_MENU
	await mPMenuHide()
	await localMpMenuShow()

# ======== Multiplayer Local Menu Buttons ========

func _on_tsu_game_pressed():
	GameManager.matchInfo.gamemode = "TSU"
	currentMenu = MenuSets.MULTIPLAYER_LOCAL_PREGAME
	await localMpMenuHide()
	await mpOptionsShow()

# ======== Other Menu Buttons ========

func _on_back_button_pressed():
	if currentMenu == MenuSets.SOLO_MENU:
		soloOptionsHide()
		await soloMenuHide()
		await mainMenuShow()
		currentMenu = MenuSets.MAIN_MENU
	elif currentMenu == MenuSets.MULTIPLAYER_MENU:
		await mPMenuHide()
		await mainMenuShow()
		currentMenu = MenuSets.MAIN_MENU
	elif currentMenu == MenuSets.MULTIPLAYER_LOCAL_MENU:
		mpOptionsHide()
		await localMpMenuHide()
		await mPMenuShow()
		currentMenu = MenuSets.MULTIPLAYER_MENU
	elif currentMenu == MenuSets.SETTINGS_MENU:
		await settingsMenuHide()
		await mainMenuShow()
		currentMenu = MenuSets.MAIN_MENU
	elif currentMenu == MenuSets.SOLO_PREGAME:
		await soloOptionsHide()
		await soloMenuShow()
		currentMenu = MenuSets.SOLO_MENU
	elif currentMenu == MenuSets.MULTIPLAYER_LOCAL_PREGAME:
		await mpOptionsHide()
		await localMpMenuShow()
		currentMenu = MenuSets.MULTIPLAYER_LOCAL_MENU

func _on_back_button_mouse_entered():
	get_tree().create_tween().tween_property($UI/BackButton, "position:x", 0, 0.2)

func _on_back_button_mouse_exited():
	get_tree().create_tween().tween_property($UI/BackButton, "position:x", -5, 0.2)

func _on_settings_tab_tab_changed(tab):
	if tab == 0:
		$UI/SettingsPanel/ControlsPanel.show()
		$UI/SettingsPanel/GameSettingsPanel.hide()
	if tab == 1:
		$UI/SettingsPanel/ControlsPanel.hide()
		$UI/SettingsPanel/GameSettingsPanel.show()

# Game options menu
func _on_speed_input_value_changed(value):
	GameManager.generalSettings.speed = value

func _on_fixed_speed_input_toggled(button_pressed):
	GameManager.soloMatchSettings.fixedSpeed = button_pressed

func _on_h_drop_input_toggled(button_pressed):
	GameManager.generalSettings.hardDrop = button_pressed

func _on_nuisance_input_toggled(button_pressed):
	GameManager.soloMatchSettings.sendNuisanceToSelf = button_pressed

func _on_time_input_value_changed(value):
	GameManager.soloMatchSettings.timeLimit = value

func _on_rounds_input_value_changed(value):
	GameManager.matchSettings.roundsToWin = value

func _on_solo_start_btn_pressed():
	if GameManager.soloMatchSettings.gamemode == "Endless":
		startSoloGame(0)
	elif GameManager.soloMatchSettings.gamemode == "Endless Tiny Puyo":
		startSoloGame(1)

func _on_mp_start_btn_pressed():
	startLocalMpGame()

func _on_char_list_item_selected(index):
	GameManager.soloMatchSettings.character = $UI/SoloOptionsPanel/CharList.get_item_text(index)

func _on_mp_char_list_item_selected(index):
	GameManager.matchSettings.p1Char = $UI/MultiplayerOptionsPanel/MPCharList.get_item_text(index)

func _on_mp_char_list_2_item_selected(index):
	GameManager.matchSettings.p2Char = $UI/MultiplayerOptionsPanel/MPCharList2.get_item_text(index)
