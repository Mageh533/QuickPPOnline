extends Area2D

var tile_size = 58
var type = "Player"
@export var fallSpeed = 100
var fastDrop = false

var bottomRaycasts = []
var leftRaycasts = []
var rightRaycasts = []

var leftWallCollide = false
var rightWallCollide = false
var groundCollide = false

var startingPos

func _ready():
	startingPos = position
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
		pieceLand()

func playerControls():
	if Input.is_action_just_pressed("right"):
		if !rightWallCollide:
			$SoundEffects/PieceMove.play()
			position += Vector2.RIGHT * tile_size
	if Input.is_action_just_pressed("left"):
		if !leftWallCollide:
			$SoundEffects/PieceMove.play()
			position += Vector2.LEFT * tile_size
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
	groundCollide = false
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
	if currentAngle == -3:
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

func pieceLand():
	$SoundEffects/PieceLand.play()
	position = startingPos
