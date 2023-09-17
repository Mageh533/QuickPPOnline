extends Control

signal playerReady

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$BG/MatchCode.text = GameManager.lobbyCode
	if GameManager.Players.size() == 1:
		$BG/PlayerListPanel/VBoxPlayers/Player1.text = GameManager.Players[GameManager.Players.keys()[0]].name
		$BG/PlayerListPanel/VBoxPlayers/Player2.text = ""
	elif GameManager.Players.size() == 2:
		$BG/PlayerListPanel/VBoxPlayers/Player1.text = GameManager.Players[GameManager.Players.keys()[0]].name
		$BG/PlayerListPanel/VBoxPlayers/Player2.text = GameManager.Players[GameManager.Players.keys()[1]].name
		if GameManager.Players[GameManager.Players.keys()[0]].id in GameManager.readyRTCPlayers:
			$BG/PlayerListPanel/VBoxPlayers/Player1.modulate = Color.GREEN
		else:
			$BG/PlayerListPanel/VBoxPlayers/Player1.modulate = Color.RED
		if GameManager.Players[GameManager.Players.keys()[1]].id in GameManager.readyRTCPlayers:
			$BG/PlayerListPanel/VBoxPlayers/Player2.modulate = Color.GREEN
		else:
			$BG/PlayerListPanel/VBoxPlayers/Player2.modulate = Color.RED

@rpc("any_peer", "call_local", "reliable")
func sendMsg(msgText, username):
	var msg = Label.new()
	msg.text = username + ": " + msgText
	$BG/ChatPanel/VBoxChat.add_child(msg)
	if $BG/ChatPanel/VBoxChat.get_child_count() > 6:
		$BG/ChatPanel/VBoxChat.get_child(0).queue_free()

@rpc("any_peer", "call_local", "reliable")
func setAsReady(id):
	GameManager.readyRTCPlayers.append(id)
	emit_signal("playerReady")

func _on_send_msg_pressed():
	var msgText = $BG/MSG.text
	sendMsg.rpc(msgText, Client.username)

func _on_ready_btn_pressed():
	setAsReady.rpc(Client.id)

func _on_disconnect_pressed():
	pass # Replace with function body.

func _on_button_pressed():
	DisplayServer.clipboard_set($BG/MatchCode.text)
