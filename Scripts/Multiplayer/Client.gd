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
var rtcPeer = WebRTCMultiplayerPeer.new()
var id = 0
var lobbyValue = ""

func _ready():
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)

func RTCServerConnected():
	print("RTC Server connected")

func RTCPeerConnected(id):
	print("RTC Peer connected: " + str(id))

func RTCPeerDisconnected(id):
	print("RTC Peer disconnected: " + str(id))

func _process(_delta):
	poll()

func poll():
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var data = JSON.parse_string(packet.get_string_from_utf32())
			print(data)
			if data.message == Message.id:
				id = data.id
				print("Connected with Id: " + str(id))
				connected(id)
				
			if data.message == Message.userConnected:
				createPeer(data.id)
				
			if data.message == Message.lobby:
				lobbyValue = data.lobbyValue
				GameManager.Players = JSON.parse_string(data.players)
				
			if data.message == Message.candidate:
				if rtcPeer.has_peer(data.orgPeer):
					print("Got candidate: " + str(data.orgPeer) + ". My id is: " + str(id))
					rtcPeer.get_peer(data.orgPeer).connection.add_ice_candidate(data.mid, data.index, data.sdp)
				
			if data.message == Message.offer:
				if rtcPeer.has_peer(data.orgPeer):
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("offer", data.data)
					
			if data.message == Message.answer:
				if rtcPeer.has_peer(data.orgPeer):
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("answer", data.data)

func connected(pId):
	rtcPeer.create_mesh(pId)
	multiplayer.multiplayer_peer = rtcPeer

#Webrtc connection
func createPeer(pId):
	if pId != self.id:
		var peer = WebRTCPeerConnection.new()
		peer.initialize({
			"iceServers" : [{"urls" : ["stun:stun.l.google.com:19302"]}]
		})
		print("Binding id: " + str(pId) + " to my id is: " + str(self.id))
		peer.session_description_created.connect(self.offer_created.bind(pId))
		peer.ice_candidate_created.connect(self.ice_candidate_created.bind(pId))
		rtcPeer.add_peer(peer, pId)
		
		if pId < rtcPeer.get_unique_id():
			peer.create_offer()

func connectToServer(_pId):
	peer.create_client("ws://127.0.0.1:4433")
	print("Client created")

func sendOffer(pId, data):
	var message = {
		"peer" : pId,
		"orgPeer" : self.id,
		"message" : Message.offer,
		"data" : data,
		"lobbyValue" : lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf32_buffer())

func sendAnswer(pId, data):
	var message = {
		"peer" : pId,
		"orgPeer" : self.id,
		"message" : Message.answer,
		"data" : data,
		"lobbyValue" : lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf32_buffer())

func ice_candidate_created(midName, indexName, sdpName, pId):
	var message = {
		"peer" : pId,
		"orgPeer" : self.id,
		"message" : Message.candidate,
		"mid" : midName,
		"index" : indexName,
		"sdp" : sdpName,
		"lobbyValue" : lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf32_buffer())

func offer_created(type, data, pId):
	if !rtcPeer.has_peer(pId):
		return
	
	rtcPeer.get_peer(pId).connection.set_local_description(type, data)
	
	if type == "offer":
		sendOffer(pId, data)
	else:
		sendAnswer(pId, data)
