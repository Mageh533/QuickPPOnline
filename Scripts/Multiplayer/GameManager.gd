extends Node

# Global variables
enum dropSetVar {
	I,
	VERTICAL_L,
	HORIZONTAL_L,
	MONO_L,
	DICH_O,
	MONO_O
}

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
	"p1Char" : "",
	"p2Char" : "",
	"roundsToWin" : 2,
}
var soloMatchSettings = {
	"gamemode" : "Endless",
	"fixedSpeed" : false,
	"timeLimit" : 120,
	"sendNuisanceToSelf" : false,
	"character" : ""
}

# In game info dictionaries
var soloInfo = {
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

func setDropset(characterSet):
	var dropSet = []
	match characterSet:
		"Amitie":
			dropSet = [dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O]
		"Arle":
			dropSet = [dropSetVar.I]
		"Carbuncle":
			dropSet = [dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.DICH_O]
		"Dongurigaeru":
			dropSet = [dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O]
		"Draco Centauros":
			dropSet = [dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.HORIZONTAL_L, dropSetVar.MONO_O, dropSetVar.HORIZONTAL_L, dropSetVar.VERTICAL_L, dropSetVar.DICH_O]
		"Ecolo":
			dropSet = [dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.HORIZONTAL_L, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.HORIZONTAL_L, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I]
		"Feli":
			dropSet = [dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I]
		"Klug":
			dropSet = [dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O]
		"Lemres":
			dropSet = [dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.HORIZONTAL_L]
		"Maguro":
			dropSet = [dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O]
		"Ms. Accord":
			dropSet = [dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.DICH_O]
		"Ocean Prince":
			dropSet = [dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.DICH_O]
		"Onion Pixy":
			dropSet = [dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O]
		"Raffine":
			dropSet = [dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O]
		"Rider":
			dropSet = [dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.DICH_O]
		"Ringo":
			dropSet = [dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.MONO_O, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.VERTICAL_L]
		"Risukuma":
			dropSet = [dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I]
		"Rulue":
			dropSet = [dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.MONO_O]
		"Satan":
			dropSet = [dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.MONO_O]
		"Schezo":
			dropSet = [dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I]
		"Sig":
			dropSet = [dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O]
		"Suketoudara":
			dropSet = [dropSetVar.I, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.MONO_O]
		"Witch":
			dropSet = [dropSetVar.HORIZONTAL_L, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.I, dropSetVar.I]
		"Yu & Rei":
			dropSet = [dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.HORIZONTAL_L, dropSetVar.I, dropSetVar.MONO_O, dropSetVar.I, dropSetVar.VERTICAL_L, dropSetVar.I, dropSetVar.DICH_O, dropSetVar.I, dropSetVar.I, dropSetVar.I, dropSetVar.DICH_O]
		_:
			dropSet = [dropSetVar.I]
	return dropSet
