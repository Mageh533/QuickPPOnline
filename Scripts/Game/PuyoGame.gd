extends Node2D

signal sendDamage(damage: int)
signal lost

@export var currentPlayer : int

var puyosObjectArray = []
var puyosToPop = []
var connectedPuyos = []
var colours = ["RED", "GREEN", "BLUE", "YELLOW", "PURPLE"]

var checkPopTimer = false
var scoreToAdd = false
var loseTile = false
var loseTileTimer = false
var defeated = false

var chainCooldown = 0
var currentChain = 0

var score = 0
var puyosClearedInChain = 0
var chainPower = 0
var colourBonus = 0
var coloursCleared = 0
var groupBonus = 0

func _ready():
	if currentPlayer == 0:
		$PuyoDropBG2.visible = false
		$NextPuyoSprites/Puyo1Set1_2.visible = false
		$NextPuyoSprites/Puyo2Set1_2.visible = false
		$NextPuyoSprites/Puyo1Set2_2.visible = false
		$NextPuyoSprites/Puyo2Set2_2.visible = false
	else:
		$PuyoDropBG1.visible = false
		$NextPuyoSprites/Puyo1Set1.visible = false
		$NextPuyoSprites/Puyo2Set1.visible = false
		$NextPuyoSprites/Puyo1Set2.visible = false
		$NextPuyoSprites/Puyo2Set2.visible = false

func _process(delta):
	connectPuyosToGame()
	$ScorePanel/ScoreLabel.text = str(score).pad_zeros(8)
	if chainCooldown > 0:
		scoreToAdd = true
		$ScorePanel/ScoreLabel.text = str(10 * puyosClearedInChain) + " x " + str(calculateChainPower() + calculateColourBonus() + groupBonus)
		chainCooldown += -delta
		if !defeated:
			get_tree().get_nodes_in_group("Player")[currentPlayer].set_process(false)
	else:
		if scoreToAdd:
			score += calculateScore()
			scoreToAdd = false
		currentChain = 0
		if !defeated:
			get_tree().get_nodes_in_group("Player")[currentPlayer].set_process(true)

# Connects their signals
func connectPuyosToGame():
	puyosObjectArray = $TileMap.get_children()
	var puyoDropPlayer = get_tree().get_nodes_in_group("Player")
	for puyo in puyosObjectArray:
		if !puyo.active and !puyo.type == "Player":
			puyo.active = true
			puyo.puyoConnected.connect(_on_puyo_connected)
	if !defeated:
		if !puyoDropPlayer[currentPlayer].active:
			puyoDropPlayer[currentPlayer].currentPlayer = currentPlayer + 1
			puyoDropPlayer[currentPlayer].active = true
			puyoDropPlayer[currentPlayer].sendNextPuyos.connect(_on_next_puyo_sent)
			puyoDropPlayer[currentPlayer].sendAfterPuyos.connect(_on_after_puyo_sent)

# If any puyo emits the signal they are connected it starts the popping timer
func _on_puyo_connected():
	if !checkPopTimer:
		checkPopTimer = true
		$PoppingTimer.start()

func _on_next_puyo_sent(puyos):
	$NextPuyoSprites/Puyo1Set1.play(puyos[0])
	$NextPuyoSprites/Puyo2Set1.play(puyos[1])
	$NextPuyoSprites/Puyo1Set1_2.play(puyos[0])
	$NextPuyoSprites/Puyo2Set1_2.play(puyos[1])

func _on_after_puyo_sent(puyos):
	$NextPuyoSprites/Puyo1Set2.play(puyos[0])
	$NextPuyoSprites/Puyo2Set2.play(puyos[1])
	$NextPuyoSprites/Puyo1Set2_2.play(puyos[0])
	$NextPuyoSprites/Puyo2Set2_2.play(puyos[1])

# Function checks if 4 or more puyos are connected, if so runs their pop function
func _on_popping_timer_timeout():
	puyosToPop.clear()
	for puyo in puyosObjectArray:
		connectedPuyos.clear()
		if puyo.type != "Player":
			findOutAllConnected(puyo)
		
		if connectedPuyos.size() > 3:
			puyosToPop.append_array(connectedPuyos)
			
	if puyosToPop.size() > 0:
		chainCooldown = 2
		currentChain += 1
		puyosClearedInChain += puyosToPop.size()
		playChainSoundEffects()
	
	if puyosToPop.size() > 4 and puyosToPop.size() < 11:
		groupBonus += 2 + (puyosToPop.size() - 5)
	elif puyosToPop.size() > 11:
		groupBonus += 10
	
	for puyoToPop in puyosToPop:
		if puyoToPop.type in colours:
			colours.erase(puyoToPop.type)
		puyoToPop.pop()
	
	checkPopTimer = false

func findOutAllConnected(puyo):
	if puyo.connected.size() > 0 and !connectedPuyos.has(puyo) and !puyo.popped and !puyosToPop.has(puyo):
		connectedPuyos.append(puyo)
		for otherPuyo in puyo.connected:
			findOutAllConnected(otherPuyo)

func playChainSoundEffects():
	await get_tree().create_timer(0.3).timeout
	if currentChain < 7:
		get_node("ChainSoundEffects/Chain" + str(currentChain)).play()
	else:
		$ChainSoundEffects/Chain7.play()

# Based on classic tsu rules
func calculateChainPower():
	var power = 0
	if currentChain > 1 and currentChain <= 5:
		power = 2 ** (currentChain + 1)
	elif currentChain > 5:
		power = 64 + (32 * currentChain - 5)
	
	return power

func calculateColourBonus():
	coloursCleared = 5 - colours.size()
	var colourB = 0
	
	if coloursCleared > 1:
		colourB = 3
		for i in range(coloursCleared - 2):
			colourB *= 2
	
	return colourB

# Calculates score and resets values to default
func calculateScore():
	chainPower = calculateChainPower()
	colourBonus = calculateColourBonus()
	var calculatedScore = (10 * puyosClearedInChain) * (chainPower + colourBonus + groupBonus)
	
	colourBonus = 0
	groupBonus = 0
	chainPower = 0
	puyosClearedInChain = 0
	colours = ["RED", "GREEN", "BLUE", "YELLOW", "PURPLE"]
	return calculatedScore

# If a puyo is on the lose tile for more than a second then its game over
func _on_lose_tile_area_entered(_area):
	loseTile = true
	if !loseTileTimer:
		loseTileTimer = true
		$LoseTimer.start()

func _on_lose_tile_area_exited(_area):
	loseTile = false

func _on_lose_timer_timeout():
	if loseTile and !defeated:
		emit_signal("lost")
		defeated = true
		get_tree().get_nodes_in_group("Player")[currentPlayer].visible = false
		get_tree().get_nodes_in_group("Player")[currentPlayer].process_mode = Node.PROCESS_MODE_DISABLED
		
	loseTileTimer = false
