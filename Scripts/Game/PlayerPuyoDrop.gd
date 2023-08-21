extends Area2D

var tile_size = 58
var type = "Player"
@export var fallSpeed = 100
@export var moveCooldownTime = 0.1
@export var PuyoScenes: Array[PackedScene]

var bottomRaycasts = []
var leftRaycasts = []
var rightRaycasts = []
var currentPuyos = []
var nextPuyos = []

var fastDrop = false
var leftWallCollide = false
var rightWallCollide = false
var groundCollide = false
var moveCooldown = false
var landCooldown = false

var startingPos

# Choses puyos 
func _ready():
	startingPos = position
	currentPuyos.append(PuyoScenes[randi() % PuyoScenes.size()])
	currentPuyos.append(PuyoScenes[randi() % PuyoScenes.size()])
	nextPuyos.append(PuyoScenes[randi() % PuyoScenes.size()])
	nextPuyos.append(PuyoScenes[randi() % PuyoScenes.size()])
	$Puyo1Sprite.play(currentPuyos[0]._bundled.get("names")[0])
	$Puyo2Sprite.play(currentPuyos[1]._bundled.get("names")[0])
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size/2


func _process(delta):
	if fastDrop:
		position += Vector2.DOWN * (fallSpeed * 8) * delta
	else:
		position += Vector2.DOWN * fallSpeed * delta
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
	playerControls()
	
	if groundCollide:
		groundCollide = false
		if !landCooldown:
			landCooldown = true
			pieceLand()
			await get_tree().create_timer(0.2).timeout
			landCooldown = false

func playerControls():
	if Input.is_action_pressed("right"):
		if !moveCooldown:
			moveCooldown = true
			await get_tree().create_timer(moveCooldownTime).timeout
			if !rightWallCollide:
				$SoundEffects/PieceMove.play()
				position += Vector2.RIGHT * tile_size
			moveCooldown = false
	if Input.is_action_pressed("left"):
		if !moveCooldown:
			moveCooldown = true
			await get_tree().create_timer(moveCooldownTime).timeout
			if !leftWallCollide:
				$SoundEffects/PieceMove.play()
				position += Vector2.LEFT * tile_size
			moveCooldown = false
	if Input.is_action_pressed("down"):
		fastDrop = true
	if Input.is_action_just_released("down"):
		fastDrop = false
	if Input.is_action_just_released("turnLeft"):
		$SoundEffects/PieceRotate.play()
		if await checkForRoationClipping():
			rotate(PI / 2)
		else:
			rotate(PI) # If trapped within 2 walls (puyos) then rotate 180 degrees
	if Input.is_action_just_released("turnRight"):
		$SoundEffects/PieceRotate.play()
		if await checkForRoationClipping():
			rotate(-PI / 2)
		else:
			rotate(PI)

# Function to find out where raycasts are after rotating
func setRayCastsPositions():
	bottomRaycasts.clear()
	leftRaycasts.clear()
	rightRaycasts.clear()
	leftWallCollide = false
	rightWallCollide = false
	var currentAngle = round(transform.get_rotation())
	print(round(transform.get_rotation()))
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
	if rightWallCollide and !leftWallCollide:
		position += Vector2.LEFT * tile_size
	elif leftWallCollide and !rightWallCollide:
		position += Vector2.RIGHT * tile_size
	elif leftWallCollide and rightWallCollide:
		canRotate = false
	return canRotate

func processSprites():
	pass

func swapPuyos():
	currentPuyos.clear()
	currentPuyos.append_array(nextPuyos)
	nextPuyos.clear()
	nextPuyos.append(PuyoScenes[randi() % PuyoScenes.size()])
	nextPuyos.append(PuyoScenes[randi() % PuyoScenes.size()])
	$Puyo1Sprite.play(currentPuyos[0]._bundled.get("names")[0])
	$Puyo2Sprite.play(currentPuyos[1]._bundled.get("names")[0])

func pieceLand():
	$SoundEffects/PieceLand.play()
	var puyo1 = currentPuyos[0].instantiate()
	var puyo2 = currentPuyos[1].instantiate()
	get_parent().add_child(puyo1)
	get_parent().add_child(puyo2)
	puyo1.global_position = $Puyo1Spawn.global_position
	puyo2.global_position = $Puyo2Spawn.global_position
	puyo1.basicSetup()
	puyo2.basicSetup()
	position = startingPos
	swapPuyos()
