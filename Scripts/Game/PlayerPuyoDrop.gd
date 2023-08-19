extends Area2D

var tile_size = 58
var type = "Player"

func _ready():
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size/2


func _process(delta):
	position = Vector2.DOWN * delta
	playerControls()

func playerControls():
	if Input.is_action_just_released("right"):
		if !$RayRight.is_colliding():
			position += Vector2.RIGHT * tile_size
	if Input.is_action_just_released("left"):
		if !$RayLeft.is_colliding():
			position += Vector2.LEFT * tile_size
	if Input.is_action_pressed("down"):
		pass
	if Input.is_action_just_released("turnLeft"):
		rotate(PI / 2)
	if Input.is_action_just_released("turnRight"):
		rotate(-PI / 2)
