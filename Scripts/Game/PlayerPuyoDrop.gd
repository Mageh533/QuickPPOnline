extends Area2D

signal sendNextPuyos(puyos)
signal sendAfterPuyos(puyos)
signal pieceLanded

var tile_size = 58
var type = "Player"
@export var fallSpeed = 100
@export var moveCooldownTime = 0.1
@export var PuyoScenes: Array[PackedScene]
var rng = RandomNumberGenerator.new()

var bottomRaycasts = []
var leftRaycasts = []
var rightRaycasts = []
var currentPuyos = []
var nextPuyos = []
var afterPuyos = []

var timeOnGround = 0
var currentPlayer = 0

var fastDrop = false
var groundCollide = false
var moveCooldown = false
var landCooldown = false
var leftWallCollide = false
var rightWallCollide = false
var active = false
var playerSet = false

var startingPos

# Choses puyos 
func _ready():
	rng.seed = GameManager.currentSeed
	startingPos = position
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
	area_shape_entered.connect(_on_area_shape_entered)
	await get_tree().create_timer(0.01).timeout # Wait for the signals to be connected
	emit_signal("sendNextPuyos", [nextPuyos[0]._bundled.get("names")[0], nextPuyos[1]._bundled.get("names")[0]])
	emit_signal("sendAfterPuyos", [afterPuyos[0]._bundled.get("names")[0], afterPuyos[1]._bundled.get("names")[0]])


func _process(delta):
	if !groundCollide:
		if timeOnGround > 0:
			timeOnGround += -delta
		if fastDrop:
			position += Vector2.DOWN * (fallSpeed + 800) * delta
		else:
			position += Vector2.DOWN * fallSpeed * delta
	setRayCastsPositions()
	for rayCast in leftRaycasts:
		if rayCast.is_colliding():
			leftWallCollide = true
	for rayCast in rightRaycasts:
		if rayCast.is_colliding():
			rightWallCollide = true
	groundCollide = false
	for rayCast in bottomRaycasts:
		if rayCast.is_colliding():
			groundCollide = true
	
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		playerControls(1) # if playing multiplayer, use the player 1 controls
	else:
		if !GameManager.onlineMatch:
			playerControls(currentPlayer)
	
	if groundCollide:
		timeOnGround += delta
		if fastDrop:
			timeOnGround += 0.1
		if !landCooldown and timeOnGround > 1:
			landCooldown = true
			pieceLand.rpc()
			await get_tree().create_timer(0.2).timeout
			landCooldown = false
	
	if active and !playerSet:
		playerSet = true
		if currentPlayer == 1:
			$MultiplayerSynchronizer.set_multiplayer_authority(1)
		else:
			$MultiplayerSynchronizer.set_multiplayer_authority(GameManager.secondPlayerId)

func playerControls(controlsToUse):
	if Input.is_action_pressed("p" + str(controlsToUse) + "_right"):
		if !moveCooldown:
			moveCooldown = true
			await get_tree().create_timer(moveCooldownTime).timeout
			if !rightWallCollide:
				var tween = get_tree().create_tween()
				$SoundEffects/PieceMove.play()
				var newPos = position.x + (tile_size)
				tween.tween_property(self, "position:x", newPos, 0.1)
			moveCooldown = false
	if Input.is_action_pressed("p" + str(controlsToUse) + "_left"):
		if !moveCooldown:
			moveCooldown = true
			await get_tree().create_timer(moveCooldownTime).timeout
			if !leftWallCollide:
				var tween = get_tree().create_tween()
				$SoundEffects/PieceMove.play()
				var newPos = position.x + (-tile_size)
				tween.tween_property(self, "position:x", newPos, 0.1)
			moveCooldown = false
	if Input.is_action_just_released("p" + str(controlsToUse) + "_down") or !Input.is_action_pressed("p" + str(currentPlayer) + "_down"):
		fastDrop = false
	if Input.is_action_pressed("p" + str(controlsToUse) + "_down"):
		fastDrop = true
	if Input.is_action_just_released("p" + str(controlsToUse) + "_turnLeft"):
		$SoundEffects/PieceRotate.play()
		if await checkForRoationClipping():
			var tween = get_tree().create_tween()
			var newRot = rotation + (PI / 2)
			tween.tween_property(self, "rotation", newRot, 0.1)
		else:
			rotate180()
	if Input.is_action_just_released("p" + str(controlsToUse) + "_turnRight"):
		$SoundEffects/PieceRotate.play()
		if await checkForRoationClipping():
			var tween = get_tree().create_tween()
			var newRot = rotation + (-PI / 2)
			tween.tween_property(self, "rotation", newRot, 0.1)
		else:
			rotate180()

# Function to find out where raycasts are after rotating
func setRayCastsPositions():
	bottomRaycasts.clear()
	leftRaycasts.clear()
	rightRaycasts.clear()
	leftWallCollide = false
	rightWallCollide = false
	var currentAngle = round(transform.get_rotation())
	if currentAngle == 2:
		bottomRaycasts.append($RayCasts/RayRight)
		leftRaycasts.append($RayCasts/RayBLeft)
		leftRaycasts.append($RayCasts/RayBRight)
		rightRaycasts.append($RayCasts/RayTLeft)
		rightRaycasts.append($RayCasts/RayTRight)
	if currentAngle == 0:
		bottomRaycasts.append($RayCasts/RayBLeft)
		bottomRaycasts.append($RayCasts/RayBRight)
		leftRaycasts.append($RayCasts/RayLeft)
		rightRaycasts.append($RayCasts/RayRight)
	if currentAngle == -2:
		bottomRaycasts.append($RayCasts/RayLeft)
		rightRaycasts.append($RayCasts/RayBLeft)
		rightRaycasts.append($RayCasts/RayBRight)
		leftRaycasts.append($RayCasts/RayTLeft)
		leftRaycasts.append($RayCasts/RayTRight)
	if currentAngle == -3 or currentAngle == 3:
		bottomRaycasts.append($RayCasts/RayTLeft)
		bottomRaycasts.append($RayCasts/RayTRight)
		rightRaycasts.append($RayCasts/RayLeft)
		leftRaycasts.append($RayCasts/RayRight)

# Prevents clipping 
func checkForRoationClipping():
	var canRotate = true
	if $RayCasts/RayBRight.is_colliding() or $RayCasts/RayTRight.is_colliding():
		if rightWallCollide and !leftWallCollide:
			position += Vector2.LEFT * tile_size
		elif leftWallCollide and !rightWallCollide:
			position += Vector2.RIGHT * tile_size
		else:
			canRotate = false
	return canRotate

func rotate180():
	var temp = $Puyo1Spawn.position
	$Puyo1Spawn.position = $Puyo2Spawn.position
	$Puyo2Spawn.position = temp
	temp = $RemoteTransformP1.position
	$RemoteTransformP1.position = $RemoteTransformP2.position
	$RemoteTransformP2.position = temp

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

@rpc("any_peer", "call_local", "reliable")
func pieceLand():
	$SoundEffects/PieceLand.play()
	var puyo1 = currentPuyos[0].instantiate()
	var puyo2 = currentPuyos[1].instantiate()
	get_parent().add_child(puyo1)
	get_parent().add_child(puyo2)
	puyo1.global_position = $Puyo1Spawn.global_position + (Vector2.RIGHT * 1)
	puyo2.global_position = $Puyo2Spawn.global_position + (Vector2.RIGHT * 1)
	puyo1.basicSetup()
	puyo2.basicSetup()
	position = startingPos
	timeOnGround = 0
	swapPuyos()
	rotation = deg_to_rad(90)
	emit_signal("pieceLanded")

# The actual collision shape of this object should never touch something else
func _on_area_shape_entered(_area_rid, area, _area_shape_index, _local_shape_index):
	if area.type != "Nuisance":
		if !rightWallCollide and !leftWallCollide:
			timeOnGround += 1
			position += Vector2.UP * tile_size

func _on_body_shape_entered(_body_rid, _body, _body_shape_index, _local_shape_index):
	timeOnGround += 1
	position += Vector2.UP * tile_size
