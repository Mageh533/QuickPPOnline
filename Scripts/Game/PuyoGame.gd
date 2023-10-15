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

var puyosObjectArray = []
var puyosToPop = []
var connectedPuyos = []
var colours = ["RED", "GREEN", "BLUE", "YELLOW", "PURPLE"]

var scoreToAdd = false
var defeated = false

var loseTileTime = 0
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
var feverGauge = 0
var feverTime = 15

func _ready():
	setPlayerColor()
	setPlayerCharacter()
	
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
		$CharacterBackground.flip_h = true
	
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
			emit_signal("sendDamage", calculateNuisance(chainScore, nuisanceTarget))
			nuisanceProcess()
	
	if feverMode:
		$FeverGauge/FeverBG1/FeverTime.text = str(feverTime)
		$FeverGauge/FeverBG2/FeverTime.text = str(feverTime)
	
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
			emit_signal("attacking", false)
			disablePlayer(false)

# Check if a puyo is on the losetile, then emit a lost signal if true
func _physics_process(delta):
	if !defeated:
		var loseTileTouch = false
		for losetileSprite in $LoseTiles.get_children():
			if losetileSprite.get_child(0).is_colliding():
				loseTileTime += delta
				loseTileTouch = true
		
		if !loseTileTouch:
			loseTileTime = 0
		
		if loseTileTime > 0.5:
			defeated = true
			emit_signal("lost")
			disablePlayer(true)

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

func displayPuyoQueue(bg : String, pSet : String, puyos):
	# randomize nothing to a random int so they wont match up as actual puyos
	var puyosI = puyos
	for i in range(puyosI.size()):
		if puyosI[i] == "Nothing":
			puyosI[i] = str(randi())
	if puyosI[0] == puyosI[1] and puyosI[3] != puyosI[2] and !puyosI[3].is_valid_int(): #Vertical L
		# Hide and show sprites
		get_node("PuyoDrop" + bg + "/PuyoVertical" + pSet).show()
		get_node("PuyoDrop" + bg + "/PuyoDich1" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoDich2" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoHorizontal" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoMono" + pSet).hide()
		get_node("PuyoDrop" + bg + "/Puyo1" + pSet).hide()
		get_node("PuyoDrop" + bg + "/Puyo2" + pSet).hide()
		get_node("PuyoDrop" + bg + "/Puyo4" + pSet).show()
		# Play anims
		get_node("PuyoDrop" + bg + "/PuyoVertical" + pSet).play(puyosI[0])
		get_node("PuyoDrop" + bg + "/PuyoVertical" + pSet + "/Eyes").play(puyosI[0])
		get_node("PuyoDrop" + bg + "/Puyo4" + pSet).play(puyosI[3])
	elif puyosI[1] == puyosI[3] and puyosI[0] != puyosI[2] and puyosI[0] != puyosI[1] and !puyosI[0].is_valid_int(): # Horizontal L
		# Hide and show sprites
		get_node("PuyoDrop" + bg + "/PuyoVertical" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoDich1" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoDich2" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoHorizontal" + pSet).show()
		get_node("PuyoDrop" + bg + "/PuyoMono" + pSet).hide()
		get_node("PuyoDrop" + bg + "/Puyo1" + pSet).show()
		get_node("PuyoDrop" + bg + "/Puyo2" + pSet).hide()
		get_node("PuyoDrop" + bg + "/Puyo4" + pSet).hide()
		# Play anims
		get_node("PuyoDrop" + bg + "/Puyo1" + pSet).play(puyosI[3])
		get_node("PuyoDrop" + bg + "/PuyoHorizontal" + pSet).play(puyosI[0])
		get_node("PuyoDrop" + bg + "/PuyoHorizontal" + pSet + "/Eyes").play(puyosI[0])
	elif puyosI[0] == puyosI[1] and puyosI[0] == puyosI[2] and puyosI[0] == puyosI[3]: # Mono O
		# Hide and show sprites
		get_node("PuyoDrop" + bg + "/PuyoVertical" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoDich1" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoDich2" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoHorizontal" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoMono" + pSet).show()
		get_node("PuyoDrop" + bg + "/PuyoMono" + pSet + "/Eyes").hide()
		get_node("PuyoDrop" + bg + "/Puyo1" + pSet).hide()
		get_node("PuyoDrop" + bg + "/Puyo2" + pSet).hide()
		get_node("PuyoDrop" + bg + "/Puyo4" + pSet).hide()
		# Play anims
		get_node("PuyoDrop" + bg + "/PuyoMono" + pSet).play(puyosI[0])
	elif puyosI[0] == puyosI[1] and puyosI[0] == puyosI[3] and puyosI[0] != puyosI[2]: # Mono L
		# Hide and show sprites
		get_node("PuyoDrop" + bg + "/PuyoVertical" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoDich1" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoDich2" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoHorizontal" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoMono" + pSet).show()
		get_node("PuyoDrop" + bg + "/PuyoMono" + pSet + "/Eyes").show()
		get_node("PuyoDrop" + bg + "/Puyo1" + pSet).hide()
		get_node("PuyoDrop" + bg + "/Puyo2" + pSet).hide()
		get_node("PuyoDrop" + bg + "/Puyo4" + pSet).hide()
		# Play anims
		get_node("PuyoDrop" + bg + "/PuyoMono" + pSet).play(puyosI[0] + "L")
		get_node("PuyoDrop" + bg + "/PuyoMono" + pSet + "/Eyes").play(puyosI[0])
	elif puyosI[0] == puyosI[1] and puyosI[2] == puyosI[3]: # Dichromatic O
		# Hide and show sprites
		get_node("PuyoDrop" + bg + "/PuyoVertical" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoDich1" + pSet).show()
		get_node("PuyoDrop" + bg + "/PuyoDich2" + pSet).show()
		get_node("PuyoDrop" + bg + "/PuyoHorizontal" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoMono" + pSet).hide()
		get_node("PuyoDrop" + bg + "/Puyo1" + pSet).hide()
		get_node("PuyoDrop" + bg + "/Puyo2" + pSet).hide()
		get_node("PuyoDrop" + bg + "/Puyo4" + pSet).hide()
		# Play anims
		get_node("PuyoDrop" + bg + "/PuyoDich1" + pSet).play(puyosI[0])
		get_node("PuyoDrop" + bg + "/PuyoDich1" + pSet + "/Eyes").play(puyosI[0])
		get_node("PuyoDrop" + bg + "/PuyoDich2" + pSet).play(puyosI[2])
		get_node("PuyoDrop" + bg + "/PuyoDich2" + pSet + "/Eyes").play(puyosI[2])
	else:
		# Hide and show sprites
		get_node("PuyoDrop" + bg + "/PuyoVertical" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoDich1" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoDich2" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoHorizontal" + pSet).hide()
		get_node("PuyoDrop" + bg + "/PuyoMono" + pSet).hide()
		get_node("PuyoDrop" + bg + "/Puyo1" + pSet).show()
		get_node("PuyoDrop" + bg + "/Puyo2" + pSet).show()
		get_node("PuyoDrop" + bg + "/Puyo4" + pSet).hide()
		# Play anims
		get_node("PuyoDrop" + bg + "/Puyo1" + pSet).play(puyosI[0])
		get_node("PuyoDrop" + bg + "/Puyo2" + pSet).play(puyosI[1])

func _on_next_puyo_sent(puyos):
	displayPuyoQueue("BG1", "Set1", puyos)
	displayPuyoQueue("BG2", "Set1", puyos)

func _on_after_puyo_sent(puyos):
	displayPuyoQueue("BG1", "Set2", puyos)
	displayPuyoQueue("BG2", "Set2", puyos)

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
			emit_signal("offsettingGarbase")
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

func queueNuisance(nuisanceNum):
	nuisanceQueue += nuisanceNum

# Function to get all spawn points in the case grid is bigger or smaller e.g, tiny puyo and mega puyo gamemodes
func getNuisanceSpawnPoints():
	var freeSpawnPoints = []
	for nuisanceSpawn in $NuisanceSpawns.get_children():
		freeSpawnPoints.append(nuisanceSpawn.name.to_int())
	return freeSpawnPoints

# Nuisance spawns in rows and stack up
func spawnNuisance(nuisanceNum):
	var nuisanceSpawnPoints = $NuisanceSpawns.get_children()
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
			$TileMap.add_child(nuisance)
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

func setPlayerColor():
	$TileMap.set_layer_modulate(0, playerColor)
	$ScorePanel.self_modulate = playerColor
	$PuyoDropBG1.self_modulate = playerColor
	$PuyoDropBG2.self_modulate = playerColor

func setPlayerCharacter(iCharacter : String = ""):
	if !iCharacter.is_empty():
		character = iCharacter
		$CharacterBackground.texture = load("res://Assets/Characters/" + character + "/field.png")
		$CharacterBackground.show()
	else:
		if !character.is_empty():
			$CharacterBackground.texture = load("res://Assets/Characters/" + character + "/field.png")
			$CharacterBackground.show()

func _on_piece_landed():
	await get_tree().create_timer(0.2).timeout
	nuisanceProcess()
