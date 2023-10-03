extends Node2D

signal sendDamage(damage)
signal lost

@export var currentPlayer : int
@export var nuisanceTarget: float
@export var nuisanceScene : PackedScene

var puyosObjectArray = []
var puyosToPop = []
var connectedPuyos = []
var colours = ["RED", "GREEN", "BLUE", "YELLOW", "PURPLE"]

var scoreToAdd = false
var loseTile = false
var loseTileTimer = false
var defeated = false

var chainCooldown = 0
var nuisanceCooldown = 0
var checkChainTime = 0
var currentChain = 0
var leftOverNuisance = 0
@export var nuisanceQueue = 0

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
	$AllClear.visible = false

func _process(delta):
	connectPuyosToGame()
	$ScorePanel/ScoreLabel.text = str(score).pad_zeros(8)
	if chainCooldown > 0 or nuisanceCooldown > 0:
		$ScorePanel/ScoreLabel.text = str(10 * puyosClearedInChain) + " x " + str(calculateChainPower() + calculateColourBonus() + groupBonus)
		if chainCooldown > 0:
			scoreToAdd = true
			chainCooldown += -delta
		if nuisanceCooldown > 0:
			nuisanceCooldown += -delta
	else:
		if scoreToAdd:
			scoreToAdd = false
			var chainScore = calculateScore()
			score += chainScore
			emit_signal("sendDamage", calculateNuisance(chainScore, nuisanceTarget))
			await get_tree().create_timer(0.5).timeout
			nuisanceProcess()
	
	if !defeated:
		var movingPuyos = false
		for puyo in puyosObjectArray:
			if puyo.type != "Player":
				if puyo.moving:
					movingPuyos = true
		if movingPuyos or nuisanceCooldown > 0 or chainCooldown > 0 or checkForChain():
			disablePlayer(true)
			if checkForChain():
				checkChainTime += delta
				if checkChainTime > 0.5:
					checkChainTime = 0
					startChain()
		else:
			currentChain = 0
			disablePlayer(false)

# Connects their signals
func connectPuyosToGame():
	puyosObjectArray = $TileMap.get_children()
	var puyoDropPlayer = get_tree().get_nodes_in_group("Player")
	for puyo in puyosObjectArray:
		if !puyo.active and !puyo.type == "Player" and !puyo.type == "Nuisance":
			puyo.active = true
	if !defeated:
		if !puyoDropPlayer[currentPlayer].active:
			puyoDropPlayer[currentPlayer].currentPlayer = currentPlayer + 1
			puyoDropPlayer[currentPlayer].active = true
			puyoDropPlayer[currentPlayer].sendNextPuyos.connect(_on_next_puyo_sent)
			puyoDropPlayer[currentPlayer].sendAfterPuyos.connect(_on_after_puyo_sent)
			puyoDropPlayer[currentPlayer].pieceLanded.connect(_on_piece_landed)

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

func checkForChain():
	var canChain = false
	puyosToPop.clear()
	for puyo in puyosObjectArray:
		connectedPuyos.clear()
		if puyo.type != "Player" and puyo.type != "Nuisance":
			findOutAllConnected(puyo)
		
		if connectedPuyos.size() > 3:
			puyosToPop.append_array(connectedPuyos)
			canChain = true
	return canChain

func startChain():
	checkForChain()
	
	if puyosToPop.size() > 0:
		chainCooldown = 2
		currentChain += 1
		puyosClearedInChain += puyosToPop.size()
		playChainEffects(puyosToPop[0].global_position)
	
	if puyosToPop.size() > 4 and puyosToPop.size() < 11:
		groupBonus += 2 + (puyosToPop.size() - 5)
	elif puyosToPop.size() > 11:
		groupBonus += 10
	
	for puyoToPop in puyosToPop:
		if puyoToPop.type in colours:
			colours.erase(puyoToPop.type)
		puyoToPop.pop()
	
	if checkAllClear() and currentChain > 0:
		await get_tree().create_timer(0.5).timeout
		$Anims.play("all_clear")

func findOutAllConnected(puyo):
	if puyo.connected.size() > 0 and !connectedPuyos.has(puyo) and !puyo.popped and !puyosToPop.has(puyo):
		connectedPuyos.append(puyo)
		for otherPuyo in puyo.connected:
			findOutAllConnected(otherPuyo)

func playChainEffects(chainPos):
	await get_tree().create_timer(0.3).timeout
	if currentChain < 7 and currentChain > 0:
		get_node("ChainSoundEffects/Chain" + str(currentChain)).play()
	else:
		$ChainSoundEffects/Chain7.play()
	
	$ChainLabel.text = str(currentChain) + " Chain!"
	$ChainLabel.global_position = chainPos + (Vector2.UP * 200)
	var tween = get_tree().create_tween()
	tween.tween_property($ChainLabel, "global_position", chainPos + (Vector2.UP * 100), 0.5)
	$ChainLabel.show()
	await get_tree().create_timer(1).timeout
	$ChainLabel.hide()

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

func calculateNuisance(chainScore, targetPoints):
	var nuisancePoints = chainScore / targetPoints + leftOverNuisance
	var nuisanceToSend = floor(nuisancePoints)
	leftOverNuisance = nuisancePoints - nuisanceToSend
	if checkAllClear():
		nuisanceToSend += 30
	if nuisanceQueue > 0:
		var temp = nuisanceQueue
		nuisanceQueue -= nuisanceToSend
		nuisanceToSend -= temp
		if nuisanceQueue < 0:
			nuisanceQueue = 0
	return nuisanceToSend

func queueNuisance(nuisanceNum):
	nuisanceQueue += nuisanceNum

# Nuisance spawns in rows and stack up
func spawnNuisance(nuisanceNum):
	var nuisanceSpawnPoints = $NuisanceSpawns.get_children()
	var tile_size = 58
	var stack = 0
	var freeSpawnPoints = [0, 1, 2, 3, 4, 5]
	var nuisanceToSpawn = nuisanceNum
	while nuisanceToSpawn > 0:
		if freeSpawnPoints.size() > 0:
			var nuisance = nuisanceScene.instantiate()
			var spawnToUse = freeSpawnPoints[randi() % freeSpawnPoints.size()]
			freeSpawnPoints.erase(spawnToUse)
			nuisance.position = nuisanceSpawnPoints[spawnToUse].position + (stack * (Vector2.UP * tile_size))
			$TileMap.add_child(nuisance)
			nuisanceToSpawn += -1
		else:
			stack += 1
			freeSpawnPoints = [0, 1, 2, 3, 4, 5]
	if nuisanceNum < 12:
		$MultiplayerSoundEffects/Damage1.play()
	else:
		$MultiplayerSoundEffects/Damage2.play()

func checkAllClear():
	var allClear = true
	for puyo in $TileMap.get_children():
		if puyo.type != "Player" and !puyo.popped:
			allClear = false
	return allClear

func nuisanceProcess():
	if chainCooldown <= 0:
		if nuisanceQueue > 0:
			nuisanceCooldown = 2
			await get_tree().create_timer(1).timeout
			if chainCooldown > 0:
				return
			else:
				if nuisanceQueue >= 30:
					spawnNuisance(30)
					nuisanceQueue -= 30
				else:
					spawnNuisance(nuisanceQueue)
					nuisanceQueue = 0

func disablePlayer(disable : bool):
	if disable:
		get_tree().get_nodes_in_group("Player")[currentPlayer].resetPlayer()
		get_tree().get_nodes_in_group("Player")[currentPlayer].set_process(false)
		get_tree().get_nodes_in_group("Player")[currentPlayer].set_physics_process(false)
		get_tree().get_nodes_in_group("Player")[currentPlayer].visible = false
	else:
		get_tree().get_nodes_in_group("Player")[currentPlayer].set_process(true)
		get_tree().get_nodes_in_group("Player")[currentPlayer].set_physics_process(true)
		get_tree().get_nodes_in_group("Player")[currentPlayer].visible = true

func _on_lose_timer_timeout():
	if loseTile and !defeated:
		emit_signal("lost")
		defeated = true
		disablePlayer(true)
		
	loseTileTimer = false

func _on_piece_landed():
	await get_tree().create_timer(0.2).timeout
	nuisanceProcess()

func _on_lose_tile_area_entered(_area):
	loseTile = true
	if !loseTileTimer:
		loseTileTimer = true
		$LoseTimer.start()


func _on_lose_tile_area_exited(_area):
	loseTile = false
