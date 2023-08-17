extends Area2D

var tile_size = 58
var moving = false
var type = "RED"
var connected = []

# Called when the node enters the scene tree for the first time.
func _ready():
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size/2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !moving:
		print("Searching...")
		searchOtherPuyos()


# 'Gravity' for the puyos that works similarly to the actual games, also stays within the tilemap
func _on_gravity_timer_timeout():
	if(!$RayBottom.is_colliding()):
		moving = true
		position += Vector2.DOWN * tile_size
	else:
		moving = false

func searchOtherPuyos():
	if $RayTop.is_colliding():
		if $RayTop.get_collider().type == "RED":
			updateSpriteFrame("TOP")
	if $RayBottom.is_colliding():
		if $RayBottom.get_collider().type == "RED":
			updateSpriteFrame("BOTTOM")
	if $RayLeft.is_colliding():
		if $RayLeft.get_collider().type == "RED":
			updateSpriteFrame("LEFT")
	if $RayRight.is_colliding():
		if $RayRight.get_collider().type == "RED":
			updateSpriteFrame("RIGHT")

func updateSpriteFrame(collidingSide):
	$AnimatedSprite2D.play()
