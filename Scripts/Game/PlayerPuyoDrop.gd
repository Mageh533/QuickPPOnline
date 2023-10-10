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

var timeOnGround = 0
var currentPlayer = 0

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
var largePiece = false

var startingPos
var startingRot

# Choses puyos 
func _ready():
	setUpPuyoGroup()

func _physics_process(delta):
	if fastDrop:
		velocity.y = (fallSpeed + 800) * delta * (get_parent().global_scale.y * 50)
		move_and_slide()
	else:
		velocity.y = fallSpeed * delta * (get_parent().global_scale.y * 50)
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
	
	if currentDropSet.is_empty():
		disableAdditionalPieces(true)
	
	if active and !playerSet:
		playerSet = true
		if currentPlayer == 1:
			$MultiplayerSynchronizer.set_multiplayer_authority(1)
		else:
			$MultiplayerSynchronizer.set_multiplayer_authority(GameManager.secondPlayerId)

func setUpPuyoGroup():
	rng.seed = GameManager.currentSeed
	startingPos = position
	startingRot = rotation
	currentPuyos.append(PuyoScenes[rng.randi() % PuyoScenes.size()])
	currentPuyos.append(PuyoScenes[rng.randi() % PuyoScenes.size()])
	nextPuyos.append(PuyoScenes[rng.randi() % PuyoScenes.size()])
	nextPuyos.append(PuyoScenes[rng.randi() % PuyoScenes.size()])
	afterPuyos.append(PuyoScenes[rng.randi() % PuyoScenes.size()])
	afterPuyos.append(PuyoScenes[rng.randi() % PuyoScenes.size()])
	$Puyo1Sprite.play(currentPuyos[0]._bundled.get("names")[0])
	$Puyo2Sprite.play(currentPuyos[1]._bundled.get("names")[0])
	position = position.snapped(Vector2.ONE * tile_size)
	position += -Vector2.ONE * tile_size/2
	await get_tree().create_timer(0.01).timeout # Wait for the signals to be connected
	$SpritesTransforms.global_position = global_position
	interpolate = true
	emit_signal("sendNextPuyos", [nextPuyos[0]._bundled.get("names")[0], nextPuyos[1]._bundled.get("names")[0]])
	emit_signal("sendAfterPuyos", [afterPuyos[0]._bundled.get("names")[0], afterPuyos[1]._bundled.get("names")[0]])
	fallSpeed = GameManager.generalSettings.speed * 10
	if GameManager.matchSettings.gamemode == "Fever":
		currentDropSet = GameManager.setDropset(get_parent().get_parent().character)
	elif GameManager.soloMatchSettings.gamemode == "Endless Tiny Puyo":
		currentDropSet = GameManager.setDropset("Solo")

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
			rotate180()
	if Input.is_action_just_pressed("p" + str(controlsToUse) + "_up"):
		if GameManager.generalSettings.hardDrop:
			pieceLand(true)

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
	if currentAngle == 0:
		topRaycasts.append($RayCasts/RayTLeft)
		topRaycasts.append($RayCasts/RayTRight)
		bottomRaycasts.append($RayCasts/RayBLeft)
		bottomRaycasts.append($RayCasts/RayBRight)
		leftRaycasts.append($RayCasts/RayLeft)
		rightRaycasts.append($RayCasts/RayRight)
	if currentAngle == -2:
		bottomRaycasts.append($RayCasts/RayRight)
		bottomRaycasts.append($RayCasts/RayLeft)
		rightRaycasts.append($RayCasts/RayBLeft)
		rightRaycasts.append($RayCasts/RayBRight)
		leftRaycasts.append($RayCasts/RayTLeft)
		leftRaycasts.append($RayCasts/RayTRight)
	if currentAngle == -3 or currentAngle == 3:
		topRaycasts.append($RayCasts/RayBLeft)
		topRaycasts.append($RayCasts/RayBRight)
		bottomRaycasts.append($RayCasts/RayTLeft)
		bottomRaycasts.append($RayCasts/RayTRight)
		rightRaycasts.append($RayCasts/RayLeft)
		leftRaycasts.append($RayCasts/RayRight)

# Prevents clipping 
func checkForRoationClipping():
	var canRotate = true
	if rightWallCollide and leftWallCollide:
		var currentAngle = round(transform.get_rotation())
		if currentAngle == -2 or currentAngle == 2:
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

func swapPuyos():
	currentPuyos.clear()
	currentPuyos.append_array(nextPuyos)
	nextPuyos.clear()
	nextPuyos.append_array(afterPuyos)
	emit_signal("sendNextPuyos", [nextPuyos[0]._bundled.get("names")[0], nextPuyos[1]._bundled.get("names")[0]])
	afterPuyos.clear()
	afterPuyos.append(PuyoScenes[rng.randi() % PuyoScenes.size()])
	afterPuyos.append(PuyoScenes[rng.randi() % PuyoScenes.size()])
	emit_signal("sendAfterPuyos", [afterPuyos[0]._bundled.get("names")[0], afterPuyos[1]._bundled.get("names")[0]])
	$Puyo1Sprite.play(currentPuyos[0]._bundled.get("names")[0])
	$Puyo2Sprite.play(currentPuyos[1]._bundled.get("names")[0])

func resetPlayer():
	interpolate = false
	position = startingPos
	rotation = startingRot
	$SpritesTransforms.global_position = global_position
	interpolate = true

func disableAdditionalPieces(disabled : bool):
	for raycast in $RayCasts2.get_children():
		raycast.enabled = !disabled
	$Puyo1Collision3.disabled = disabled
	$Puyo1Collision4.disabled = disabled
	$Puyo3Sprite.visible = !disabled
	$Puyo4Sprite.visible = !disabled

@rpc("any_peer", "call_local", "reliable")
func pieceLand(hardDrop : bool = false):
	$SoundEffects/PieceLand.play()
	var puyo1 = currentPuyos[0].instantiate()
	var puyo2 = currentPuyos[1].instantiate()
	get_parent().add_child(puyo1)
	get_parent().add_child(puyo2)
	puyo1.global_position = $Puyo1Spawn.global_position + (Vector2.RIGHT * 1)
	puyo2.global_position = $Puyo2Spawn.global_position + (Vector2.RIGHT * 1)
	if hardDrop:
		puyo1.hardDrop = hardDrop
		puyo2.hardDrop = hardDrop
	puyo1.basicSetup()
	puyo2.basicSetup()
	resetPlayer()
	timeOnGround = 0
	swapPuyos()
	$Transforms.rotation = rotation
	$SpritesTransforms.rotation = rotation
	emit_signal("pieceLanded")
	await get_tree().create_timer(0.01).timeout
