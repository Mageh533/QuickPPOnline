extends Node2D

signal sendDamage(damage)
signal sendPoppedPuyos(puyos)
signal attackingDamage(attack)
signal attacking(attacking)
signal offsettingGarbage
signal lost

@export var currentPlayer : int
@export var nuisanceTarget: float
@export var nuisanceScene : PackedScene
@export var playerColor : Color
@export var character : String
@export var feverMode : bool
@export var dropSets : bool
@export var feverGauge = 0

var puyosObjectArray = []
var puyosToPop = []
var connectedPuyos = []
var colours = ["RED", "GREEN", "BLUE", "YELLOW", "PURPLE"]
var puyoStoreArray = []

var puyoSpriteBG1InitPos = []
var puyoSpriteBG2InitPos = []

var scoreToAdd = false
var defeated = false
var feverActive = false
var puyoBoardStored = false

var firstPuyoSet = 0
var puyoQueueAfterPos = 3
var loseTileTime = 0
var chainCooldown = 0
var nuisanceCooldown = 0
var landCooldown = 0
var checkChainTime = 0
var currentChain = 0
var leftOverNuisance = 0
@export var nuisanceQueue = 0

var score = 0
var dropScore = 0
var puyosClearedInChain = 0
var chainPower = 0
var colourBonus = 0
var coloursCleared = 0
var groupBonus = 0
var feverTime = 15

func _ready():
	setPlayerColor()
	setPlayerCharacter()
	puyoSpriteBG1InitPos.append($PuyoDropBG1/SpriteSet1.position + (Vector2.UP * 100))
	puyoSpriteBG1InitPos.append($PuyoDropBG1/SpriteSet1.position)
	puyoSpriteBG1InitPos.append($PuyoDropBG1/SpriteSet2.position)
	puyoSpriteBG1InitPos.append($PuyoDropBG1/SpriteSet3.position)
	puyoSpriteBG2InitPos.append($PuyoDropBG2/SpriteSet1.position + (Vector2.UP * 100))
	puyoSpriteBG2InitPos.append($PuyoDropBG2/SpriteSet1.position)
	puyoSpriteBG2InitPos.append($PuyoDropBG2/SpriteSet2.position)
	puyoSpriteBG2InitPos.append($PuyoDropBG2/SpriteSet3.position)
	
	if feverMode:
		$FeverGauge.show()
	else:
		$FeverGauge.hide()
	
	if currentPlayer == 0:
		$PuyoDropBG2.hide()
		$FeverGauge/FeverBG2.hide()
		$FeverGauge/FeverOverlay2.hide()
	else:
		$PuyoDropBG1.hide()
		$FeverGauge/FeverBG1.hide()
		$FeverGauge/FeverOverlay1.hide()
		$GamePanel/GameContainer/GameView/PuyoGameBoard/CharacterBackground.flip_h = true
	
	$AllClear.visible = false

func _process(delta):
	connectPuyosToGame()
	$ScorePanel/ScoreLabel.text = str(score).pad_zeros(8)
	if chainCooldown > 0 or nuisanceCooldown > 0:
		if chainCooldown > 0:
			if currentChain > 2:
				emit_signal("attacking", true)
			$ScorePanel/ScoreLabel.text = str(10 * puyosClearedInChain) + " x " + str(calculateChainPower() + calculateColourBonus() + groupBonus)
			var chainScore = (10 * puyosClearedInChain) * (calculateChainPower() + calculateColourBonus() + groupBonus)
			emit_signal("attackingDamage", chainScore)
			scoreToAdd = true
			chainCooldown += -delta
		if nuisanceCooldown > 0:
			nuisanceCooldown += -delta
	else:
		if scoreToAdd:
			scoreToAdd = false
			var chainScore = calculateScore()
			score += chainScore
			# Fast drop counts towards nuisance similarly to pp 20th and ppt
			emit_signal("sendDamage", calculateNuisance(chainScore + dropScore, nuisanceTarget))
			dropScore = 0
			nuisanceProcess()
	
	if feverMode:
		processFeverMode(delta)
	
	if !defeated:
		var movingPuyos = false
		for puyo in puyosObjectArray:
			if puyo.type != "Player":
				if puyo.moving:
					movingPuyos = true
		if movingPuyos or nuisanceCooldown > 0 or chainCooldown > 0 or checkForChain():
			disablePlayer(true)
			landCooldown = 0.1
			if checkForChain():
				checkChainTime += delta
				if checkChainTime > 0.5:
					checkChainTime = 0
					startChain()
		else:
			# Clear fever board if the player did a chain of 2 or more. E.g., they didnt do the fever chain properly
			if currentChain > 1 and feverActive:
				clearFeverBoard()
				sendNextFeverChain()
			currentChain = 0
			emit_signal("attacking", false)
			disablePlayer(false)
		
		if landCooldown > 0:
			landCooldown -= delta
			disablePlayer(true)
		else:
			disablePlayer(false)

# Check if a puyo is on the losetile, then emit a lost signal if true
func _physics_process(delta):
	if !defeated:
		var loseTileTouch = false
		for losetileSprite in $GamePanel/GameContainer/GameView/PuyoGameBoard/LoseTiles.get_children():
			if losetileSprite.get_child(0).is_colliding():
				loseTileTime += delta
				loseTileTouch = true
		
		if !loseTileTouch:
			loseTileTime = 0
		
		if loseTileTime > 0.5:
			defeated = true
			emit_signal("lost")
			disablePlayer(true)

func processFeverMode(delta):
	$FeverGauge/FeverBG1/FeverTime.text = str(floor(feverTime))
	$FeverGauge/FeverBG2/FeverTime.text = str(floor(feverTime))
	if feverActive:
		$GamePanel/GameContainer/GameView/PuyoGameBoard/FeverBackground.show()
		if currentChain == 0:
			feverTime -= delta
		if !puyoBoardStored:
			get_tree().get_nodes_in_group("Player")[currentPlayer].resetPlayer()
			puyoStoreArray.clear()
			for puyo in $TileMap.get_children():
				if puyo is StaticBody2D:
					puyoStoreArray.append(puyo)
					puyo.process_mode = Node.PROCESS_MODE_DISABLED
					puyo.hide()
			sendNextFeverChain()
			puyoBoardStored = true
		if feverTime <= 0:
			feverTime = 15
			feverActive = false
			if puyoBoardStored:
				get_tree().get_nodes_in_group("Player")[currentPlayer].resetPlayer()
				clearFeverBoard()
				for puyo in puyoStoreArray:
					puyo.process_mode = Node.PROCESS_MODE_INHERIT
					puyo.show()
				puyoBoardStored = false
			feverGauge = 0
	else:
		$GamePanel/GameContainer/GameView/PuyoGameBoard/FeverBackground.hide()

func sendNextFeverChain():
	var tileSet = $TileMap.tile_set
	var randomChain = tileSet.get_pattern(randi() % tileSet.get_patterns_count())
	$TileMap.set_pattern(1, Vector2i(0, -10), randomChain)

func clearFeverBoard():
	for puyo in $TileMap.get_children():
		if puyo is StaticBody2D and !puyo in puyoStoreArray:
			puyo.queue_free()

# Connects their signals
func connectPuyosToGame():
	puyosObjectArray = $GamePanel/GameContainer/GameView/PuyoGameBoard/TileMap.get_children()
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
			puyoDropPlayer[currentPlayer].fastDropBonus.connect(_on_fast_drop_bonus)

func _on_fast_drop_bonus():
	dropScore += 1
	score += 1

func displayPuyoQueue(bg : String, pSet : String, puyos):
	# randomize nothing to a random int so they wont match up as actual puyos
	var puyosI = puyos
	for i in range(puyosI.size()):
		if puyosI[i] == "Nothing":
			puyosI[i] = str(randi())
	if puyosI[0] == puyosI[1] and puyosI[3] != puyosI[2] and !puyosI[3].is_valid_int(): #Vertical L
		# Hide and show sprites
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoVertical").show()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich1").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich2").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoHorizontal").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoMono").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo1").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo2").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo4").show()
		# Play anims
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoVertical").play(puyosI[0])
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoVertical" + "/Eyes").play(puyosI[0])
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo4").play(puyosI[3])
	elif puyosI[1] == puyosI[3] and puyosI[0] != puyosI[2] and puyosI[0] != puyosI[1] and !puyosI[0].is_valid_int(): # Horizontal L
		# Hide and show sprites
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoVertical").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich1").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich2").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoHorizontal").show()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoMono").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo1").show()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo2").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo4").hide()
		# Play anims
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo1").play(puyosI[3])
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoHorizontal").play(puyosI[0])
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoHorizontal" + "/Eyes").play(puyosI[0])
	elif puyosI[0] == puyosI[1] and puyosI[0] == puyosI[2] and puyosI[0] == puyosI[3]: # Mono O
		# Hide and show sprites
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoVertical").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich1").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich2").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoHorizontal").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoMono").show()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoMono" + "/Eyes").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo1").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo2").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo4").hide()
		# Play anims
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoMono").play(puyosI[0])
	elif puyosI[0] == puyosI[1] and puyosI[0] == puyosI[3] and puyosI[0] != puyosI[2]: # Mono L
		# Hide and show sprites
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoVertical").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich1").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich2").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoHorizontal").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoMono").show()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoMono" + "/Eyes").show()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo1").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo2").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo4").hide()
		# Play anims
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoMono").play(puyosI[0] + "L")
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoMono" + "/Eyes").play(puyosI[0])
	elif puyosI[0] == puyosI[1] and puyosI[2] == puyosI[3]: # Dichromatic O
		# Hide and show sprites
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoVertical").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich1").show()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich2").show()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoHorizontal").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoMono").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo1").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo2").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo4").hide()
		# Play anims
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich1").play(puyosI[0])
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich1" + "/Eyes").play(puyosI[0])
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich2").play(puyosI[2])
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich2" + "/Eyes").play(puyosI[2])
	else:
		# Hide and show sprites
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoVertical").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich1").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoDich2").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoHorizontal").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/PuyoMono").hide()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo1").show()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo2").show()
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo4").hide()
		# Play anims
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo1").play(puyosI[1])
		get_node("PuyoDrop" + bg +  "/SpriteSet" + pSet +"/Puyo2").play(puyosI[0])

func _on_next_puyo_sent(puyos):
	if firstPuyoSet < 2:
		displayPuyoQueue("BG1", "1", puyos)
		displayPuyoQueue("BG2", "1", puyos)

func _on_after_puyo_sent(puyos):
	if firstPuyoSet < 2:
		displayPuyoQueue("BG1", "2", puyos)
		displayPuyoQueue("BG2", "2", puyos)
		firstPuyoSet += 1
	else:
		displayPuyoQueue("BG1", str(puyoQueueAfterPos), puyos)
		displayPuyoQueue("BG2", str(puyoQueueAfterPos), puyos)
		await cyclePuyoQueue()
		puyoQueueAfterPos += 1
		if puyoQueueAfterPos > 3:
			puyoQueueAfterPos = 1

func cyclePuyoQueue():
	var topTween = get_tree().create_tween()
	var topTween2 = get_tree().create_tween()
	topTween.tween_property(get_node("PuyoDropBG1/SpriteSet" + str(wrapi(puyoQueueAfterPos - 2, 1, 4))), "position", puyoSpriteBG1InitPos[0], 0.3)
	get_tree().create_tween().tween_property(get_node("PuyoDropBG1/SpriteSet" + str(wrapi(puyoQueueAfterPos - 1, 1, 4))), "position", puyoSpriteBG1InitPos[1], 0.3)
	get_tree().create_tween().tween_property(get_node("PuyoDropBG1/SpriteSet" + str(wrapi(puyoQueueAfterPos - 1, 1, 4))), "scale", Vector2(1, 1), 0.3)
	get_tree().create_tween().tween_property(get_node("PuyoDropBG1/SpriteSet" + str(puyoQueueAfterPos)), "position", puyoSpriteBG1InitPos[2], 0.3)
	get_tree().create_tween().tween_property(get_node("PuyoDropBG1/SpriteSet" + str(puyoQueueAfterPos)), "scale", Vector2(0.75, 0.75), 0.3)
	topTween2.tween_property(get_node("PuyoDropBG2/SpriteSet" + str(wrapi(puyoQueueAfterPos - 2, 1, 4))), "position", puyoSpriteBG2InitPos[0], 0.3)
	get_tree().create_tween().tween_property(get_node("PuyoDropBG2/SpriteSet" + str(wrapi(puyoQueueAfterPos - 1, 1, 4))), "position", puyoSpriteBG2InitPos[1], 0.3)
	get_tree().create_tween().tween_property(get_node("PuyoDropBG2/SpriteSet" + str(wrapi(puyoQueueAfterPos - 1, 1, 4))), "scale", Vector2(1, 1), 0.3)
	get_tree().create_tween().tween_property(get_node("PuyoDropBG2/SpriteSet" + str(puyoQueueAfterPos)), "position", puyoSpriteBG2InitPos[2], 0.3)
	get_tree().create_tween().tween_property(get_node("PuyoDropBG2/SpriteSet" + str(puyoQueueAfterPos)), "scale", Vector2(0.75, 0.75), 0.3)
	await topTween.finished
	get_node("PuyoDropBG1/SpriteSet" + str(wrapi(puyoQueueAfterPos - 2, 1, 4))).position = puyoSpriteBG1InitPos[3]
	await topTween2.finished
	get_node("PuyoDropBG2/SpriteSet" + str(wrapi(puyoQueueAfterPos - 2, 1, 4))).position = puyoSpriteBG2InitPos[3]

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
	
	emit_signal("sendPoppedPuyos", puyosToPop.size())
	
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
	$ChainLabel.global_position = chainPos
	var tween = get_tree().create_tween()
	tween.tween_property($ChainLabel, "global_position", chainPos + (Vector2.UP * 50), 0.5)
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
		leftOverNuisance += 30
	if nuisanceQueue > 0:
		var temp = nuisanceQueue
		if feverMode:
			emit_signal("offsettingGarbage")
			increaseFeverGauge()
		nuisanceQueue -= nuisanceToSend
		nuisanceToSend -= temp
		if nuisanceQueue < 0:
			nuisanceQueue = 0
	return nuisanceToSend

func increaseFeverGauge():
	feverGauge += 1
	for i in range(feverGauge):
		get_node('FeverGauge/FeverBG1/Fever' + str(i + 1)).modulate = playerColor
		get_node('FeverGauge/FeverBG2/Fever' + str(i + 1)).modulate = playerColor
	if feverGauge >= 7:
		feverGauge = 0
		feverActive = true

func queueNuisance(nuisanceNum):
	nuisanceQueue += nuisanceNum

# Function to get all spawn points in the case grid is bigger or smaller e.g, tiny puyo and mega puyo gamemodes
func getNuisanceSpawnPoints():
	var freeSpawnPoints = []
	for nuisanceSpawn in $GamePanel/GameContainer/GameView/PuyoGameBoard/NuisanceSpawns.get_children():
		freeSpawnPoints.append(nuisanceSpawn.name.to_int())
	return freeSpawnPoints

# Nuisance spawns in rows and stack up
func spawnNuisance(nuisanceNum):
	var nuisanceSpawnPoints = $GamePanel/GameContainer/GameView/PuyoGameBoard/NuisanceSpawns.get_children()
	var tile_size = 58
	var stack = 0
	var freeSpawnPoints = getNuisanceSpawnPoints()
	var nuisanceToSpawn = nuisanceNum
	while nuisanceToSpawn > 0:
		if freeSpawnPoints.size() > 0:
			var nuisance = nuisanceScene.instantiate()
			var spawnToUse = freeSpawnPoints[randi() % freeSpawnPoints.size()]
			freeSpawnPoints.erase(spawnToUse)
			nuisance.position = nuisanceSpawnPoints[spawnToUse].position + (stack * (Vector2.UP * tile_size))
			$GamePanel/GameContainer/GameView/PuyoGameBoard/TileMap.add_child(nuisance)
			nuisanceToSpawn += -1
		else:
			stack += 1
			freeSpawnPoints = getNuisanceSpawnPoints()
	if nuisanceNum < 6:
		$MultiplayerSoundEffects/Damage1.play()
	else:
		$MultiplayerSoundEffects/Damage2.play()

func checkAllClear():
	var allClear = true
	for puyo in $GamePanel/GameContainer/GameView/PuyoGameBoard/TileMap.get_children():
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

func setPlayerColor():
	$GamePanel.self_modulate = playerColor
	$ScorePanel.self_modulate = playerColor
	$PuyoDropBG1.self_modulate = playerColor
	$PuyoDropBG2.self_modulate = playerColor

func setPlayerCharacter(iCharacter : String = ""):
	if !iCharacter.is_empty():
		character = iCharacter
		$GamePanel/GameContainer/GameView/PuyoGameBoard/CharacterBackground.texture = load("res://Assets/Characters/" + character + "/field.png")
		$GamePanel/GameContainer/GameView/PuyoGameBoard/CharacterBackground.show()
	else:
		if !character.is_empty():
			$GamePanel/GameContainer/GameView/PuyoGameBoard/CharacterBackground.texture = load("res://Assets/Characters/" + character + "/field.png")
			$GamePanel/GameContainer/GameView/PuyoGameBoard/CharacterBackground.show()

func _on_piece_landed():
	await get_tree().create_timer(0.2).timeout
	if !checkForChain():
		dropScore = 0
	nuisanceProcess()
