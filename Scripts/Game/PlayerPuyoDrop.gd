extends Area2D

var tile_size = 58
var type = "Player"
@onready var currentGravity = $GravityTimer.wait_time
@onready var fastDropSpeed = $GravityTimer.wait_time / 2

func _ready():
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size/2


func _process(_delta):
	playerControls()


func _on_gravity_timer_timeout():
	if !$RayLeft.is_colliding() and !$RayRight.is_colliding() and !$RayTLeft.is_colliding() and !$RayTRight.is_colliding() and !$RayBLeft.is_colliding() and !$RayBRight.is_colliding():
		position += Vector2.DOWN * tile_size

func playerControls():
	if Input.is_action_just_released("right"):
		if !$RayRight.is_colliding():
			position += Vector2.RIGHT * tile_size
	if Input.is_action_just_released("left"):
		if !$RayLeft.is_colliding():
			position += Vector2.LEFT * tile_size
	if Input.is_action_pressed("down"):
		$GravityTimer.wait_time = fastDropSpeed
	if Input.is_action_just_released("down"):
		$GravityTimer.wait_time = currentGravity
	if Input.is_action_just_released("turnLeft"):
		rotate(PI / 2)
	if Input.is_action_just_released("turnRight"):
		rotate(-PI / 2)
