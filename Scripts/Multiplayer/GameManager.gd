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
var matchSettings = {
	"roundsToWin" : 2
}
var matchInfo = {
	"matchTime" : 0,
	"p1Wins" : 0,
	"p2Wins" : 0
}

# Global functions

func changeControls(player, control, key):
	var controlToChange = player + "_" + control
	InputMap.action_erase_events(controlToChange)
	InputMap.action_add_event(controlToChange, key)
