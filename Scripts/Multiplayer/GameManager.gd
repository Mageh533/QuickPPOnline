extends Node

# Global variables

var onlineMatch = false
var fpsCounter = false

var secondPlayerId = 0
var currentSeed = 0

var soloInfo = {
	"Mode" : "Endless",
	"matchTime" : 0,
	"maxChain" : 0,
	"speed" : 0
}
var matchInfo = {
	"matchTime" : 0,
	"p1Wins" : 0,
	"p2Wins" : 0
}
var matchSettings = {
	"roundsToWin" : 2
}
var soloMatchSettings = {
	"speed" : 5
}

# Global functions

func changeControls(control, key):
	InputMap.action_erase_events(control)
	InputMap.action_add_event(control, key)
