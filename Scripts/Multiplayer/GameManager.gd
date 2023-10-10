extends Node

# Global variables

var onlineMatch = false
var secondPlayerId = 0
var currentSeed = 0

# Settings dictionaries
var clientSettings = {
	"moveSpeed" : 0.08,
	"fpsCounter" : false,
	"enableVoices" : false
}
var generalSettings = {
	"hardDrop" : false,
	"speed" : 5
}
var matchSettings = {
	"gamemode" : "TSU",
	"roundsToWin" : 2,
}
var soloMatchSettings = {
	"gamemode" : "Endless",
	"fixedSpeed" : false,
	"timeLimit" : 0,
	"sendNuisanceToSelf" : false
}

# In game info dictionaries
var soloInfo = {
	"Mode" : "Endless",
	"matchTime" : 0,
	"maxChain" : 0,
	"speed" : 0,
	"active" : false
}
var matchInfo = {
	"matchTime" : 0,
	"p1Wins" : 0,
	"p2Wins" : 0
}

# Global functions
func nuisanceDisplayHelper(nuisanceQueueSprites, nuisanceToShow, spritesToUse):
	var spritesUsed = 0
	while nuisanceToShow > 0 and spritesUsed < spritesToUse:
		if nuisanceToShow < 6:
			nuisanceQueueSprites[spritesUsed].visible = true
			nuisanceQueueSprites[spritesUsed].play("small")
			spritesUsed += 1
			nuisanceToShow -= 1
		elif nuisanceToShow >= 6 and nuisanceToShow < 30:
			nuisanceQueueSprites[spritesUsed].visible = true
			nuisanceQueueSprites[spritesUsed].play("large")
			spritesUsed += 1
			nuisanceToShow -= 6
		elif nuisanceToShow >= 30 and nuisanceToShow < 180:
			nuisanceQueueSprites[spritesUsed].visible = true
			nuisanceQueueSprites[spritesUsed].play("rock")
			spritesUsed += 1
			nuisanceToShow -= 30
		elif nuisanceToShow >= 180 and nuisanceToShow < 360:
			nuisanceQueueSprites[spritesUsed].visible = true
			nuisanceQueueSprites[spritesUsed].play("star")
			spritesUsed += 1
			nuisanceToShow -= 180
		elif nuisanceToShow >= 360 and nuisanceToShow < 720:
			nuisanceQueueSprites[spritesUsed].visible = true
			nuisanceQueueSprites[spritesUsed].play("moon")
			spritesUsed += 1
			nuisanceToShow -= 360
		elif nuisanceToShow >= 720 and nuisanceToShow < 1440:
			nuisanceQueueSprites[spritesUsed].visible = true
			nuisanceQueueSprites[spritesUsed].play("crown")
			spritesUsed += 1
			nuisanceToShow -= 720
		elif nuisanceToShow >= 1440:
			nuisanceQueueSprites[spritesUsed].visible = true
			nuisanceQueueSprites[spritesUsed].play("comet")
			spritesUsed += 1
			nuisanceToShow -= 1440

func changeControls(control, key):
	InputMap.action_erase_events(control)
	InputMap.action_add_event(control, key)
