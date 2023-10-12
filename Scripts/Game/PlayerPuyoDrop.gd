extends CharacterBody2D

signal sendNextPuyos(puyos)
signal sendAfterPuyos(puyos)
signal pieceLanded

var tile_size = 58
var type = "Player"
@export var fallSpeed = 100
@export var moveCooldownTime = 0.1
@export var PuyoScenes: Array[PackedScene]
var rng = RandomNumberGenerator.new()

var topRaycasts = []
var bottomRaycasts = []
var leftRaycasts = []
var rightRaycasts = []
var currentPuyos = []
var nextPuyos = []
var afterPuyos = []
var currentDropSet = []

var puyoSpawnsInitPos = []

var timeOnGround = 0
var currentPlayer = 0
var dropsetNum = 0

var fastDrop = false
var ceilingCollide = false
var groundCollide = false
var moveCooldown = false
var landCooldown = false
var leftWallCollide = false
var rightWallCollide = false
var active = false
var playerSet = false
var interpolate = false

var startingPos
var startingRot

# Set up the puyo group with bunch of stuff 
func _ready():
	setUpPuyoGroup()

func _physics_process(delta):
	if fastDrop:
		velocity.y = (fallSpeed + 500) * delta * (get_parent().global_scale.y * 75) * 2
		move_and_slide()
	else:
		velocity.y = fallSpeed * delta * (get_parent().global_scale.y * 75) * 2
		move_and_slide()
	
	$SpritesTransforms.global_position.y = global_position.y
	
	if (groundCollide or is_on_floor()) and !ceilingCollide:
		timeOnGround += delta
		if fastDrop:
			timeOnGround += 0.1
		if !landCooldown and timeOnGround > 0.7:
			landCooldown = true
			pieceLand.rpc()
			await get_tree().create_timer(0.2).timeout
			landCooldown = false
	
	if playerSet:
		if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
			playerControls(1) # if playing multiplayer, use the player 1 controls
		else:
			if !GameManager.onlineMatch:
				playerControls(currentPlayer)

func _process(_delta):
	if interpolate:
		$SpritesTransforms.global_position.x = move_toward($SpritesTransforms.global_position.x, global_position.x, 5)
	
	setRayCastsPositions()
	for rayCast in leftRaycasts:
		if rayCast.is_colliding():
			leftWallCollide = true
	for rayCast in rightRaycasts:
		if rayCast.is_colliding():
			rightWallCollide = true
	for rayCast in bottomRaycasts:
		if rayCast.is_colliding():
			groundCollide = true
	for rayCast in topRaycasts:
		if rayCast.is_colliding():
			ceilingCollide = true
	
	disableAdditionalPieces()
	
	if active and !playerSet:
		playerSet = true
		puyoSpawnsInitPos = [$Puyo1Spawn.position, $Puyo2Spawn.position, $Puyo3Spawn.position, $Puyo4Spawn.position, ]
		if currentPlayer == 1:
			$MultiplayerSynchronizer.set_multiplayer_authority(1)
		else:
			$MultiplayerSynchronizer.set_multiplayer_authority(GameManager.secondPlayerId)

# Massive set up, too much going on here
func setUpPuyoGroup():
	rng.seed = GameManager.currentSeed
	startingPos = position
	startingRot = rotation
	if currentDropSet.is_empty():
		currentPuyos = getNewPuyos()
		nextPuyos = getNewPuyos()
		afterPuyos = getNewPuyos()
	else:
		# get new puyos but check if the dropset that is to come in the list is dichromatic, wraps around the list as well
		currentPuyos = getNewPuyos(checkForDichromatic(currentDropSet[dropsetNum]))
		nextPuyos = getNewPuyos(checkForDichromatic(currentDropSet[wrapi(dropsetNum + 1, 0, currentDropSet.size())]))
		afterPuyos = getNewPuyos(checkForDichromatic(currentDropSet[wrapi(dropsetNum + 2, 0, currentDropSet.size())]))
	displayGroupSprites()
	position = position.snapped(Vector2.ONE * tile_size)
	position += -Vector2.ONE * tile_size/2
	await get_tree().create_timer(0.01).timeout # Wait for the signals to be connected
	$SpritesTransforms.global_position = global_position
	interpolate = true
	sendPuyoSignal("sendNextPuyos", [nextPuyos[0]._bundled.get("names")[0], nextPuyos[1]._bundled.get("names")[0]], wrapi(dropsetNum + 1, 0, currentDropSet.size()))
	sendPuyoSignal("sendAfterPuyos", [afterPuyos[0]._bundled.get("names")[0], afterPuyos[1]._bundled.get("names")[0]], wrapi(dropsetNum + 2, 0, currentDropSet.size()))
	fallSpeed = GameManager.generalSettings.speed * 10
	if GameManager.matchSettings.gamemode == "Fever" or GameManager.soloMatchSettings.gamemode == "Endless Tiny Puyo":
		currentDropSet = GameManager.setDropset(get_parent().get_parent().character)

func playerControls(controlsToUse):
	if Input.is_action_pressed("p" + str(controlsToUse) + "_right"):
		if !moveCooldown:
			moveCooldown = true
			await get_tree().create_timer(moveCooldownTime).timeout
			if !rightWallCollide and !ceilingCollide:
				$SoundEffects/PieceMove.play()
				move_and_collide(Vector2.RIGHT * (tile_size * get_parent().global_scale.x))
			moveCooldown = false
	if Input.is_action_pressed("p" + str(controlsToUse) + "_left"):
		if !moveCooldown:
			moveCooldown = true
			await get_tree().create_timer(moveCooldownTime).timeout
			if !leftWallCollide and !ceilingCollide:
				$SoundEffects/PieceMove.play()
				move_and_collide(Vector2.LEFT * (tile_size * get_parent().global_scale.x))
			moveCooldown = false
	if Input.is_action_just_released("p" + str(controlsToUse) + "_down") or !Input.is_action_pressed("p" + str(currentPlayer) + "_down"):
		fastDrop = false
	if Input.is_action_pressed("p" + str(controlsToUse) + "_down"):
		fastDrop = true
	if Input.is_action_just_released("p" + str(controlsToUse) + "_turnLeft"):
		$SoundEffects/PieceRotate.play()
		if checkForRoationClipping():
			var tween = get_tree().create_tween()
			var tween2 = get_tree().create_tween()
			rotate(PI / 2)
			tween.tween_property($Transforms, "rotation", lerp_angle($Transforms.rotation, rotation, 1),0.1)
			tween2.tween_property($SpritesTransforms, "rotation", lerp_angle($Transforms.rotation, rotation, 1), 0.1)
		else:
			if !currentDropSet.is_empty() and currentDropSet[dropsetNum] == GameManager.dropSetVar.MONO_O:
				cycleColours(0)
			elif !currentDropSet.is_empty() and currentDropSet[dropsetNum] == GameManager.dropSetVar.DICH_O:
				rotateOPiece(0)
			else:
				rotate180()
	if Input.is_action_just_released("p" + str(controlsToUse) + "_turnRight"):
		$SoundEffects/PieceRotate.play()
		if checkForRoationClipping():
			var tween = get_tree().create_tween()
			var tween2 = get_tree().create_tween()
			rotate(-PI / 2)
			tween.tween_property($Transforms, "rotation", lerp_angle($Transforms.rotation, rotation, 1),0.1)
			tween2.tween_property($SpritesTransforms, "rotation", lerp_angle($Transforms.rotation, rotation, 1), 0.1)
		else:
			if !currentDropSet.is_empty() and currentDropSet[dropsetNum] == GameManager.dropSetVar.MONO_O:
				cycleColours(1)
			elif !currentDropSet.is_empty() and currentDropSet[dropsetNum] == GameManager.dropSetVar.DICH_O:
				rotateOPiece(1)
			else:
				rotate180()
	if Input.is_action_just_pressed("p" + str(controlsToUse) + "_up"):
		if GameManager.generalSettings.hardDrop:
			pieceLand(true)

func cycleColours(dir : int):
	if dir == 0:
		if currentPuyos[0] == PuyoScenes[0]:
			currentPuyos[0] = PuyoScenes[1]
		elif currentPuyos[0] == PuyoScenes[1]:
			currentPuyos[0] = PuyoScenes[2]
		elif currentPuyos[0] == PuyoScenes[2]:
			currentPuyos[0] = PuyoScenes[3]
		elif currentPuyos[0] == PuyoScenes[3]:
			currentPuyos[0] = PuyoScenes[4]
		else:
			currentPuyos[0] = PuyoScenes[0]
	else:
		if currentPuyos[0] == PuyoScenes[0]:
			currentPuyos[0] = PuyoScenes[4]
		elif currentPuyos[0] == PuyoScenes[1]:
			currentPuyos[0] = PuyoScenes[0]
		elif currentPuyos[0] == PuyoScenes[2]:
			currentPuyos[0] = PuyoScenes[1]
		elif currentPuyos[0] == PuyoScenes[3]:
			currentPuyos[0] = PuyoScenes[2]
		else:
			currentPuyos[0] = PuyoScenes[3]
	displayGroupSprites()

# Function to find out where raycasts are after rotating
func setRayCastsPositions():
	topRaycasts.clear()
	bottomRaycasts.clear()
	leftRaycasts.clear()
	rightRaycasts.clear()
	leftWallCollide = false
	rightWallCollide = false
	groundCollide = false
	ceilingCollide = false
	var currentAngle = round(transform.get_rotation())
	if currentAngle == 2:
		topRaycasts.append($RayCasts/RayLeft)
		bottomRaycasts.append($RayCasts/RayRight)
		leftRaycasts.append($RayCasts/RayBLeft)
		leftRaycasts.append($RayCasts/RayBRight)
		rightRaycasts.append($RayCasts/RayTLeft)
		rightRaycasts.append($RayCasts/RayTRight)
		topRaycasts.append($RayCasts2/RayLeft)
		bottomRaycasts.append($RayCasts2/RayRight)
		leftRaycasts.append($RayCasts2/RayBLeft)
		leftRaycasts.append($RayCasts2/RayBRight)
		rightRaycasts.append($RayCasts2/RayTLeft)
		rightRaycasts.append($RayCasts2/RayTRight)
	if currentAngle == 0:
		topRaycasts.append($RayCasts/RayTLeft)
		topRaycasts.append($RayCasts/RayTRight)
		bottomRaycasts.append($RayCasts/RayBLeft)
		bottomRaycasts.append($RayCasts/RayBRight)
		leftRaycasts.append($RayCasts/RayLeft)
		rightRaycasts.append($RayCasts/RayRight)
		topRaycasts.append($RayCasts2/RayTLeft)
		topRaycasts.append($RayCasts2/RayTRight)
		bottomRaycasts.append($RayCasts2/RayBLeft)
		bottomRaycasts.append($RayCasts2/RayBRight)
		leftRaycasts.append($RayCasts2/RayLeft)
		rightRaycasts.append($RayCasts2/RayRight)
	if currentAngle == -2:
		bottomRaycasts.append($RayCasts/RayRight)
		bottomRaycasts.append($RayCasts/RayLeft)
		rightRaycasts.append($RayCasts/RayBLeft)
		rightRaycasts.append($RayCasts/RayBRight)
		leftRaycasts.append($RayCasts/RayTLeft)
		leftRaycasts.append($RayCasts/RayTRight)
		bottomRaycasts.append($RayCasts2/RayRight)
		bottomRaycasts.append($RayCasts2/RayLeft)
		rightRaycasts.append($RayCasts2/RayBLeft)
		rightRaycasts.append($RayCasts2/RayBRight)
		leftRaycasts.append($RayCasts2/RayTLeft)
		leftRaycasts.append($RayCasts2/RayTRight)
	if currentAngle == -3 or currentAngle == 3:
		topRaycasts.append($RayCasts/RayBLeft)
		topRaycasts.append($RayCasts/RayBRight)
		bottomRaycasts.append($RayCasts/RayTLeft)
		bottomRaycasts.append($RayCasts/RayTRight)
		rightRaycasts.append($RayCasts/RayLeft)
		leftRaycasts.append($RayCasts/RayRight)
		topRaycasts.append($RayCasts2/RayBLeft)
		topRaycasts.append($RayCasts2/RayBRight)
		bottomRaycasts.append($RayCasts2/RayTLeft)
		bottomRaycasts.append($RayCasts2/RayTRight)
		rightRaycasts.append($RayCasts2/RayLeft)
		leftRaycasts.append($RayCasts2/RayRight)

# Prevents clipping 
func checkForRoationClipping():
	var canRotate = true
	if rightWallCollide and leftWallCollide:
		var currentAngle = round(transform.get_rotation())
		if currentAngle == -2 or currentAngle == 2:
			if currentDropSet.is_empty() or currentDropSet[dropsetNum] == GameManager.dropSetVar.I:
				canRotate = false
	if !currentDropSet.is_empty():
		if currentDropSet[dropsetNum] == GameManager.dropSetVar.MONO_O or currentDropSet[dropsetNum] == GameManager.dropSetVar.DICH_O:
			canRotate = false
	return canRotate

func rotate180():
	var tween = get_tree().create_tween()
	var tween2 = get_tree().create_tween()
	var temp = $Puyo1Spawn.position
	$Puyo1Spawn.position = $Puyo2Spawn.position
	$Puyo2Spawn.position = temp
	var p1 = $SpritesTransforms/PuyoSprite1.position
	var p2 = $SpritesTransforms/PuyoSprite2.position
	tween.tween_property($SpritesTransforms/PuyoSprite1, "position", p2, 0.1)
	tween2.tween_property($SpritesTransforms/PuyoSprite2, "position", p1, 0.1)

func rotateOPiece(dir):
	var tween = get_tree().create_tween()
	var temp1 = $Puyo1Spawn.position
	var temp2 = $Puyo3Spawn.position
	if dir == 0:
		$Puyo1Spawn.position = $Puyo2Spawn.position
		$Puyo2Spawn.position = temp2
		$Puyo3Spawn.position = $Puyo4Spawn.position
		$Puyo4Spawn.position = temp1
		tween.tween_property($SpritesTransforms/DichOTransforms, "rotation", lerp_angle($SpritesTransforms/DichOTransforms.rotation, ($SpritesTransforms/DichOTransforms.rotation + PI / 2), 1), 0.1)
	else:
		$Puyo1Spawn.position = $Puyo4Spawn.position
		$Puyo3Spawn.position = $Puyo2Spawn.position
		$Puyo2Spawn.position = temp1
		$Puyo4Spawn.position = temp2
		tween.tween_property($SpritesTransforms/DichOTransforms, "rotation", lerp_angle($SpritesTransforms/DichOTransforms.rotation, ($SpritesTransforms/DichOTransforms.rotation + -PI / 2), 1), 0.1)

# Function to get new puyo colours for next drop, if dichromatic is set then it makes sure to get seperate colours
func getNewPuyos(dichromatic : bool = false):
	var puyos = []
	if dichromatic:
		puyos.append(PuyoScenes[rng.randi() % PuyoScenes.size()])
		var seperatePuyo = false
		while !seperatePuyo:
			var puyo = PuyoScenes[rng.randi() % PuyoScenes.size()]
			if puyo != puyos[0]:
				seperatePuyo = true
				puyos.append(puyo)
	else:
		puyos.append(PuyoScenes[rng.randi() % PuyoScenes.size()])
		puyos.append(PuyoScenes[rng.randi() % PuyoScenes.size()])
	return puyos

func swapPuyos():
	currentPuyos.clear()
	currentPuyos.append_array(nextPuyos)
	nextPuyos.clear()
	nextPuyos.append_array(afterPuyos)
	sendPuyoSignal("sendNextPuyos", [nextPuyos[0]._bundled.get("names")[0], nextPuyos[1]._bundled.get("names")[0]], wrapi(dropsetNum + 1, 0, currentDropSet.size()))
	afterPuyos.clear()
	if currentDropSet.is_empty():
		afterPuyos = getNewPuyos()
	else:
		afterPuyos = getNewPuyos(checkForDichromatic(currentDropSet[wrapi(dropsetNum + 2, 0, currentDropSet.size())]))
	sendPuyoSignal("sendAfterPuyos", [afterPuyos[0]._bundled.get("names")[0], afterPuyos[1]._bundled.get("names")[0]], wrapi(dropsetNum + 2, 0, currentDropSet.size()))
	displayGroupSprites()

func resetPlayer():
	# Reset spawns in case a 180 degree rotation or an o rotation was made
	for i in range(puyoSpawnsInitPos.size()):
		get_node("Puyo" + str(i + 1) +"Spawn").position = puyoSpawnsInitPos[i]
	interpolate = false
	position = startingPos
	rotation = startingRot
	$SpritesTransforms.global_position = global_position
	$SpritesTransforms/DichOTransforms.rotation = 0
	interpolate = true

func enableAdditionalPieces(enabled : bool = false, thirdPieceEn : bool = false):
	for raycast in $RayCasts2.get_children():
		raycast.enabled = enabled
	$Puyo1Collision3.disabled = !thirdPieceEn
	$Puyo1Collision4.disabled = !enabled

func disableAdditionalPieces():
	if !currentDropSet.is_empty():
		if currentDropSet[dropsetNum] == GameManager.dropSetVar.DICH_O:
			enableAdditionalPieces(true, true)
			$Puyo1Sprite.hide()
			$Puyo2Sprite.hide()
			$Puyo4Sprite.hide()
			$PuyoMonoOSprite.hide()
			$PuyoMonoLSprite.hide()
			$PuyoHorizontalSprite.hide()
			$PuyoVerticalSprite.hide()
			$PuyoDichO1.show()
			$PuyoDichO2.show()
		elif currentDropSet[dropsetNum] == GameManager.dropSetVar.MONO_O:
			enableAdditionalPieces(true, true)
			$Puyo1Sprite.hide()
			$Puyo2Sprite.hide()
			$Puyo4Sprite.hide()
			$PuyoMonoOSprite.show()
			$PuyoMonoLSprite.hide()
			$PuyoHorizontalSprite.hide()
			$PuyoVerticalSprite.hide()
			$PuyoDichO1.hide()
			$PuyoDichO2.hide()
		elif currentDropSet[dropsetNum] == GameManager.dropSetVar.MONO_L:
			enableAdditionalPieces(true, false)
			$Puyo1Sprite.hide()
			$Puyo2Sprite.hide()
			$Puyo4Sprite.hide()
			$PuyoMonoOSprite.hide()
			$PuyoMonoLSprite.show()
			$PuyoHorizontalSprite.hide()
			$PuyoVerticalSprite.hide()
			$PuyoDichO1.hide()
			$PuyoDichO2.hide()
		elif currentDropSet[dropsetNum] == GameManager.dropSetVar.VERTICAL_L:
			enableAdditionalPieces(true, false)
			$Puyo1Sprite.hide()
			$Puyo2Sprite.hide()
			$Puyo4Sprite.show()
			$PuyoMonoOSprite.hide()
			$PuyoMonoLSprite.hide()
			$PuyoHorizontalSprite.hide()
			$PuyoVerticalSprite.show()
			$PuyoDichO1.hide()
			$PuyoDichO2.hide()
		elif currentDropSet[dropsetNum] == GameManager.dropSetVar.HORIZONTAL_L:
			enableAdditionalPieces(true, false)
			$Puyo1Sprite.hide()
			$Puyo2Sprite.show()
			$Puyo4Sprite.hide()
			$PuyoMonoOSprite.hide()
			$PuyoMonoLSprite.hide()
			$PuyoHorizontalSprite.show()
			$PuyoVerticalSprite.hide()
			$PuyoDichO1.hide()
			$PuyoDichO2.hide()
		else:
			enableAdditionalPieces(false, false)
			$Puyo1Sprite.show()
			$Puyo2Sprite.show()
			$Puyo4Sprite.hide()
			$PuyoMonoOSprite.hide()
			$PuyoMonoLSprite.hide()
			$PuyoHorizontalSprite.hide()
			$PuyoVerticalSprite.hide()
			$PuyoDichO1.hide()
			$PuyoDichO2.hide()
	else:
		enableAdditionalPieces(false, false)
		$Puyo1Sprite.show()
		$Puyo2Sprite.show()
		$Puyo4Sprite.hide()
		$PuyoMonoOSprite.hide()
		$PuyoMonoLSprite.hide()
		$PuyoHorizontalSprite.hide()
		$PuyoVerticalSprite.hide()
		$PuyoDichO1.hide()
		$PuyoDichO2.hide()

func setUpMonoLPiece(hardDrop : bool = false):
	var puyo1
	var puyo2
	var puyo3
	puyo1 = currentPuyos[0].instantiate()
	puyo2 = currentPuyos[0].instantiate()
	puyo3 = currentPuyos[0].instantiate()
	get_parent().add_child(puyo1)
	get_parent().add_child(puyo2)
	get_parent().add_child(puyo3)
	puyo1.global_position = $Puyo1Spawn.global_position + (Vector2.RIGHT * 1)
	puyo2.global_position = $Puyo2Spawn.global_position + (Vector2.RIGHT * 1)
	puyo3.global_position = $Puyo3Spawn.global_position + (Vector2.RIGHT * 1)
	if hardDrop:
		puyo1.hardDrop = hardDrop
		puyo2.hardDrop = hardDrop
		puyo3.hardDrop = hardDrop
	puyo1.basicSetup()
	puyo2.basicSetup()
	puyo3.basicSetup()

func setUpMonoOPiece(hardDrop : bool = false):
	var puyo1
	var puyo2
	var puyo3
	var puyo4
	puyo1 = currentPuyos[0].instantiate()
	puyo2 = currentPuyos[0].instantiate()
	puyo3 = currentPuyos[0].instantiate()
	puyo4 = currentPuyos[0].instantiate()
	get_parent().add_child(puyo1)
	get_parent().add_child(puyo2)
	get_parent().add_child(puyo3)
	get_parent().add_child(puyo4)
	puyo1.global_position = $Puyo1Spawn.global_position + (Vector2.RIGHT * 1)
	puyo2.global_position = $Puyo2Spawn.global_position + (Vector2.RIGHT * 1)
	puyo3.global_position = $Puyo3Spawn.global_position + (Vector2.RIGHT * 1)
	puyo4.global_position = $Puyo4Spawn.global_position + (Vector2.RIGHT * 1)
	if hardDrop:
		puyo1.hardDrop = hardDrop
		puyo2.hardDrop = hardDrop
		puyo3.hardDrop = hardDrop
		puyo4.hardDrop = hardDrop
	puyo1.basicSetup()
	puyo2.basicSetup()
	puyo3.basicSetup()
	puyo4.basicSetup()

func setUpDichOPiece(hardDrop : bool = false):
	var puyo1
	var puyo2
	var puyo3
	var puyo4
	puyo1 = currentPuyos[0].instantiate()
	puyo2 = currentPuyos[0].instantiate()
	puyo3 = currentPuyos[1].instantiate()
	puyo4 = currentPuyos[1].instantiate()
	get_parent().add_child(puyo1)
	get_parent().add_child(puyo2)
	get_parent().add_child(puyo3)
	get_parent().add_child(puyo4)
	puyo1.global_position = $Puyo1Spawn.global_position + (Vector2.RIGHT * 1)
	puyo2.global_position = $Puyo2Spawn.global_position + (Vector2.RIGHT * 1)
	puyo3.global_position = $Puyo3Spawn.global_position + (Vector2.RIGHT * 1)
	puyo4.global_position = $Puyo4Spawn.global_position + (Vector2.RIGHT * 1)
	if hardDrop:
		puyo1.hardDrop = hardDrop
		puyo2.hardDrop = hardDrop
		puyo3.hardDrop = hardDrop
		puyo4.hardDrop = hardDrop
	puyo1.basicSetup()
	puyo2.basicSetup()
	puyo3.basicSetup()
	puyo4.basicSetup()

func setUpVertLPiece(hardDrop : bool = false):
	var puyo1
	var puyo2
	var puyo3
	puyo1 = currentPuyos[0].instantiate()
	puyo2 = currentPuyos[0].instantiate()
	puyo3 = currentPuyos[1].instantiate()
	get_parent().add_child(puyo1)
	get_parent().add_child(puyo2)
	get_parent().add_child(puyo3)
	puyo1.global_position = $Puyo1Spawn.global_position + (Vector2.RIGHT * 1)
	puyo2.global_position = $Puyo2Spawn.global_position + (Vector2.RIGHT * 1)
	puyo3.global_position = $Puyo4Spawn.global_position + (Vector2.RIGHT * 1)
	if hardDrop:
		puyo1.hardDrop = hardDrop
		puyo2.hardDrop = hardDrop
		puyo3.hardDrop = hardDrop
	puyo1.basicSetup()
	puyo2.basicSetup()
	puyo3.basicSetup()

func setUpHorLPiece(hardDrop : bool = false):
	var puyo1
	var puyo2
	var puyo3
	puyo1 = currentPuyos[0].instantiate()
	puyo2 = currentPuyos[1].instantiate()
	puyo3 = currentPuyos[0].instantiate()
	get_parent().add_child(puyo1)
	get_parent().add_child(puyo2)
	get_parent().add_child(puyo3)
	puyo1.global_position = $Puyo1Spawn.global_position + (Vector2.RIGHT * 1)
	puyo2.global_position = $Puyo2Spawn.global_position + (Vector2.RIGHT * 1)
	puyo3.global_position = $Puyo4Spawn.global_position + (Vector2.RIGHT * 1)
	if hardDrop:
		puyo1.hardDrop = hardDrop
		puyo2.hardDrop = hardDrop
		puyo3.hardDrop = hardDrop
	puyo1.basicSetup()
	puyo2.basicSetup()
	puyo3.basicSetup()

func setUpIPiece(hardDrop : bool = false):
	var puyo1
	var puyo2
	puyo1 = currentPuyos[0].instantiate()
	puyo2 = currentPuyos[1].instantiate()
	get_parent().add_child(puyo1)
	get_parent().add_child(puyo2)
	puyo1.global_position = $Puyo1Spawn.global_position + (Vector2.RIGHT * 1)
	puyo2.global_position = $Puyo2Spawn.global_position + (Vector2.RIGHT * 1)
	if hardDrop:
		puyo1.hardDrop = hardDrop
		puyo2.hardDrop = hardDrop
	puyo1.basicSetup()
	puyo2.basicSetup()

# Check if the next dropset is a dichromatic one e.g., needs 2 seperate colors
func checkForDichromatic(dropSetGroup):
	var dich = false
	if dropSetGroup == GameManager.dropSetVar.DICH_O or dropSetGroup == GameManager.dropSetVar.VERTICAL_L or dropSetGroup == GameManager.dropSetVar.HORIZONTAL_L:
		dich = true
	return dich

func displayGroupSprites():
	if currentDropSet.is_empty() or currentDropSet[dropsetNum] == GameManager.dropSetVar.I:
			$Puyo1Sprite.play(currentPuyos[0]._bundled.get("names")[0])
			$Puyo2Sprite.play(currentPuyos[1]._bundled.get("names")[0])
	else:
		if checkForDichromatic(currentDropSet[dropsetNum]):
			if currentDropSet[dropsetNum] == GameManager.dropSetVar.HORIZONTAL_L:
				$PuyoHorizontalSprite.play(currentPuyos[0]._bundled.get("names")[0])
				$PuyoHorizontalSprite/Eyes.play(currentPuyos[0]._bundled.get("names")[0])
				$Puyo2Sprite.play(currentPuyos[1]._bundled.get("names")[0])
			elif currentDropSet[dropsetNum] == GameManager.dropSetVar.VERTICAL_L:
				$PuyoVerticalSprite.play(currentPuyos[0]._bundled.get("names")[0])
				$PuyoVerticalSprite/Eyes.play(currentPuyos[0]._bundled.get("names")[0])
				$Puyo4Sprite.play(currentPuyos[1]._bundled.get("names")[0])
			else:
				$PuyoDichO1.play(currentPuyos[0]._bundled.get("names")[0])
				$PuyoDichO1/Eyes.play(currentPuyos[0]._bundled.get("names")[0])
				$PuyoDichO2.play(currentPuyos[1]._bundled.get("names")[0])
				$PuyoDichO2/Eyes.play(currentPuyos[1]._bundled.get("names")[0])
		else:
			if currentDropSet[dropsetNum] == GameManager.dropSetVar.MONO_L:
				$PuyoMonoLSprite.play(currentPuyos[0]._bundled.get("names")[0])
				$PuyoMonoLSprite/Eyes.play(currentPuyos[0]._bundled.get("names")[0])
			elif currentDropSet[dropsetNum] == GameManager.dropSetVar.MONO_O:
				$PuyoMonoOSprite.play(currentPuyos[0]._bundled.get("names")[0])

func sendPuyoSignal(signalName : String, puyoColours, currentDropSetNum : int):
	var puyos = []
	if currentDropSet.is_empty():
		puyos.append(puyoColours[0])
		puyos.append(puyoColours[1])
		puyos.append("Nothing")
		puyos.append("Nothing")
	else:
		if checkForDichromatic(currentDropSet[currentDropSetNum]):
			if currentDropSet[currentDropSetNum] == GameManager.dropSetVar.HORIZONTAL_L:
				puyos.append(puyoColours[0])
				puyos.append(puyoColours[1])
				puyos.append("Nothing")
				puyos.append(puyoColours[1])
			elif currentDropSet[currentDropSetNum] == GameManager.dropSetVar.DICH_O:
				puyos.append(puyoColours[0])
				puyos.append(puyoColours[0])
				puyos.append(puyoColours[1])
				puyos.append(puyoColours[1])
			else:
				puyos.append(puyoColours[0])
				puyos.append(puyoColours[0])
				puyos.append("Nothing")
				puyos.append(puyoColours[1])
		else:
			if currentDropSet[currentDropSetNum] == GameManager.dropSetVar.MONO_L:
				puyos.append(puyoColours[0])
				puyos.append(puyoColours[0])
				puyos.append("Nothing")
				puyos.append(puyoColours[0])
			elif currentDropSet[currentDropSetNum] == GameManager.dropSetVar.MONO_O:
				puyos.append(puyoColours[0])
				puyos.append(puyoColours[0])
				puyos.append(puyoColours[0])
				puyos.append(puyoColours[0])
			else:
				puyos.append(puyoColours[0])
				puyos.append(puyoColours[1])
				puyos.append("Nothing")
				puyos.append("Nothing")
	emit_signal(signalName, puyos)

@rpc("any_peer", "call_local", "reliable")
func pieceLand(hardDrop : bool = false):
	$SoundEffects/PieceLand.play()
	if !currentDropSet.is_empty():
		if currentDropSet[dropsetNum] == GameManager.dropSetVar.MONO_L:
			setUpMonoLPiece(hardDrop)
		elif currentDropSet[dropsetNum] == GameManager.dropSetVar.MONO_O:
			setUpMonoOPiece(hardDrop)
		elif currentDropSet[dropsetNum] == GameManager.dropSetVar.DICH_O:
			setUpDichOPiece(hardDrop)
		elif currentDropSet[dropsetNum] == GameManager.dropSetVar.VERTICAL_L:
			setUpVertLPiece(hardDrop)
		elif currentDropSet[dropsetNum] == GameManager.dropSetVar.HORIZONTAL_L:
			setUpHorLPiece(hardDrop)
		else:
			setUpIPiece(hardDrop)
	else:
		setUpIPiece(hardDrop)
	resetPlayer()
	timeOnGround = 0
	if !currentDropSet.is_empty():
		dropsetNum += 1
		if dropsetNum >= currentDropSet.size():
			dropsetNum = 0
	swapPuyos()
	$Transforms.rotation = rotation
	$SpritesTransforms.rotation = rotation
	emit_signal("pieceLanded")
	await get_tree().create_timer(0.01).timeout
