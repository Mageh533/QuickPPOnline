extends Node

enum Message{
	id,
	join,
	userConnected,
	userDisconnected,
	lobby,
	candidate,
	offer,
	answer,
	checkIn
}

var peer = WebSocketMultiplayerPeer.new()

func _ready():
	peer.connect("peer_connected", peer_connected)
	peer.connect("peer_disconnected", peer_disconnected)

func _process(_delta):
	poll()

func poll():
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var data = JSON.parse_string(packet.get_string_from_utf32())
			print(data)

func connectToServer(ip):
	peer.create_client("ws://127.0.0.1:4433")
	print("Client created")

func peer_connected(id):
	pass

func peer_disconnected():
	pass
