extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

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

func _on_send_msg_pressed():
	var msgText = $BG/MSG.text
	sendMsg.rpc(msgText, Client.username)

func _on_ready_btn_pressed():
	setAsReady.rpc(Client.id)

func _on_disconnect_pressed():
	pass # Replace with function body.
