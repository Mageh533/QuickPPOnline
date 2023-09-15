extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

@rpc("any_peer" ,"reliable")
func sendMsg(msgText):
	var msg = Label.new()
	msg.text = Client.username + ": " + msgText
	$BG/ChatPanel/VBoxChat.add_child(msg)
	if $BG/ChatPanel/VBoxChat.get_child_count() > 6:
		$BG/ChatPanel/VBoxChat.get_child(0).queue_free()

func _on_send_msg_pressed():
	var msgText = $BG/MSG.text
	var message = {
		"message" : Client.Message.join,
		"data" : msgText
	}
	
	sendMsg.rpc(msgText)
	Client.peer.put_packet(JSON.stringify(message).to_utf32_buffer())

func _on_ready_btn_pressed():
	pass # Replace with function body.

func _on_disconnect_pressed():
	pass # Replace with function body.
