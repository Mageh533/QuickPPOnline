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

const ALFNUM = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

var peer = WebSocketMultiplayerPeer.new()
var users = {}
var lobbies = {}

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
			
			if data.message == Message.lobby:
				JoinLobby(data.id, data.lobbyValue, data.name)

func startServer():
	peer.create_server(4433)
	print("Started server")

func JoinLobby(userId, lobbyId, username):
	if lobbyId == "":
		lobbyId = generateRandomString()
		lobbies[lobbyId] = Lobby.new(userId)
	
	var player = lobbies[lobbyId].AddPlayer(userId, username)
	
	for p in lobbies[lobbyId].Players:
		var lobbyInfo = {
			"message" : Message.lobby,
			"lobby" : JSON.stringify(lobbies[lobbyId].Players)
		}
		sendToPlayer(p, lobbyInfo)
	
	var data = {
		"message" : Message.userConnected,
		"id" : userId,
		"host" : lobbies[lobbyId].HostId,
		"player" : lobbies[lobbyId].Players[userId]
	}
	sendToPlayer(userId, data)

func sendToPlayer(userId, data):
	peer.get_peer(userId).put_packet(JSON.stringify(data).to_utf32_buffer())

func generateRandomString():
	var result = ""
	for i in range(32):
		var index = randi() % ALFNUM.length()
		result += ALFNUM[index]
	return result

func peer_connected(id):
	print("Peer connected: " + str(id))
	users[id] = {
		"id" : id,
		"message": Message.id
	}
	peer.get_peer(id).put_packet(JSON.stringify(users[id]).to_utf32_buffer())

func peer_disconnected():
	pass
