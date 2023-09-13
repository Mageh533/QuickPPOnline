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
var users = {}

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
			var dataString = packet.get_string_from_utf32()
			var data = JSON.parse_string(dataString)
			print(data)

func startServer():
	peer.create_server(4433)
	print("Started server")

func peer_connected(id):
	print("Peer connected: " + str(id))
	users[id] = {
		"id" : id
	}
	peer.get_peer(id).put_packet(JSON.stringify(users[id]).to_utf32_buffer())

func peer_disconnected():
	pass
