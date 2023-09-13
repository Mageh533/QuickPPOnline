extends RefCounted
class_name Lobby

var HostId : int
var Players : Dictionary = {}

func _init(id):
	HostId = id

func AddPlayer(id, pName):
	Players[id] = {
		"name" : pName,
		"id" : id,
		"index" : Players.size() + 1
	}
	return Players[id]
