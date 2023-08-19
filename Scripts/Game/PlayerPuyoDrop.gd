extends Area2D

var tile_size = 58
@onready var currentGravity = $GravityTimer.wait_time
@onready var fastDropSpeed = $GravityTimer.wait_time / 2
var bottomRayCast
var bottomRayCast2
var rotatedState = "VERTICAL"

func _ready():
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size/2


func _process(delta):
	var rotationInDeg = rad_to_deg(transform.get_rotation())
	if rotationInDeg == 90:
		rotatedState = "VERTICAL"
		bottomRayCast = get_node("RayBottom")
	elif rotationInDeg == 0:
		rotatedState = "HORIZONTAL"
		bottomRayCast = get_node("RayBLeft")
		bottomRayCast2 = get_node("RayBRight")
	elif rotationInDeg == -90:
		rotatedState = "VERTICAL"
		bottomRayCast = get_node("RayTop")
	elif rotationInDeg == 180:
		rotatedState = "HORIZONTAL"
		bottomRayCast = get_node("RayTLeft")
		bottomRayCast2 = get_node("RayTRight")
	playerControls()


func _on_gravity_timer_timeout():
	position += Vector2.DOWN * tile_size

func playerControls():
	if Input.is_action_just_released("right"):
		position += Vector2.RIGHT * tile_size
	if Input.is_action_just_released("left"):
		position += Vector2.LEFT * tile_size
	if Input.is_action_pressed("down"):
		$GravityTimer.wait_time = fastDropSpeed
	if Input.is_action_just_released("down"):
		$GravityTimer.wait_time = currentGravity
	if Input.is_action_just_released("turnLeft"):
		rotate(PI / 2)
	if Input.is_action_just_released("turnRight"):
		rotate(-PI / 2)
