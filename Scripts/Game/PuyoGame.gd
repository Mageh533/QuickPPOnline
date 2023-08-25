extends Node2D

signal sendDamage(damage: int)

var puyosObjectArray = []
var puyosToPop = []
var connectedPuyos = []
var colours = ["RED", "GREEN", "BLUE", "YELLOW", "PURPLE"]

var checkPopTimer = false
var soundEffectPlaying = false
var scoreToAdd = false

var chainCooldown = 0
var currentChain = 0

var score = 0
var puyosClearedInChain = 0
var chainPower = 0
var colourBonus = 0
var groupBonus = 0

func _ready():
	pass

func _process(delta):
	connectPuyosToGame()
	print(score)
	if chainCooldown > 0:
		scoreToAdd = true
		chainCooldown += -delta
		get_tree().get_nodes_in_group("Player")[0].set_process(false)
	else:
		if scoreToAdd:
			score += calculateScore()
			scoreToAdd = false
		currentChain = 0
		get_tree().get_nodes_in_group("Player")[0].set_process(true)

# Connects their signals
func connectPuyosToGame():
	puyosObjectArray = get_tree().get_nodes_in_group("Puyos")
	var puyoDropPlayer = get_tree().get_nodes_in_group("Player")
	for puyo in puyosObjectArray:
		if !puyo.active:
			puyo.active = true
			puyo.puyoConnected.connect(_on_puyo_connected)
	if !puyoDropPlayer[0].active:
		puyoDropPlayer[0].active = true
		puyoDropPlayer[0].sendNextPuyos.connect(_on_next_puyo_sent)
		puyoDropPlayer[0].sendAfterPuyos.connect(_on_after_puyo_sent)

# If any puyo emits the signal they are connected it starts the popping timer
func _on_puyo_connected():
	if !checkPopTimer:
		checkPopTimer = true
		$PoppingTimer.start()

func _on_next_puyo_sent(puyos):
	$NextPuyoSprites/Puyo1Set1.play(puyos[0])
	$NextPuyoSprites/Puyo2Set1.play(puyos[1])

func _on_after_puyo_sent(puyos):
	$NextPuyoSprites/Puyo1Set2.play(puyos[0])
	$NextPuyoSprites/Puyo2Set2.play(puyos[1])

# Function checks if 4 or more puyos are connected, if so runs their pop function
func _on_popping_timer_timeout():
	puyosToPop.clear()
	for puyo in puyosObjectArray:
		connectedPuyos.clear()
		findOutAllConnected(puyo)
		
		if connectedPuyos.size() > 3:
			puyosToPop.append_array(connectedPuyos)
			
	if puyosToPop.size() > 0:
		chainCooldown = 2
		currentChain += 1
		playChainSoundEffects()
	
	if puyosToPop.size() > 4 and puyosToPop.size() < 11:
		groupBonus += 2 + (puyosToPop.size() - 5)
	elif puyosToPop.size() > 11:
		groupBonus += 10
	
	for puyoToPop in puyosToPop:
		if puyoToPop.type in colours:
			colourBonus += 1
			colours.erase(puyoToPop.type)
		puyoToPop.pop()
		puyosClearedInChain += 1
	
	checkPopTimer = false

func findOutAllConnected(puyo):
	if puyo.connected.size() > 0 and !connectedPuyos.has(puyo) and !puyo.popped:
		connectedPuyos.append(puyo)
		for otherPuyo in puyo.connected:
			findOutAllConnected(otherPuyo)

func playChainSoundEffects():
	await get_tree().create_timer(0.3).timeout
	if currentChain < 7:
		get_node("ChainSoundEffects/Chain" + str(currentChain)).play()
	else:
		$ChainSoundEffects/Chain7.play()

# Calculate chain power, colour bonus and group bonus. Then the overall score.
func calculateScore():
	if currentChain > 1 and currentChain <= 5:
		chainPower = 2 ** currentChain
	elif currentChain > 5:
		chainPower = 64 + (32 * currentChain - 5)

	var calculatedScore = (10 * puyosClearedInChain) * (chainPower + colourBonus + groupBonus)
	
	colourBonus = 0
	groupBonus = 0
	chainPower = 0
	puyosClearedInChain = 0
	colours = ["RED", "GREEN", "BLUE", "YELLOW", "PURPLE"]
	return calculatedScore
