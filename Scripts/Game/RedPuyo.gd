extends Area2D

var tile_size = 58

var moving = false
var popped = false
var type = "RED"
var connected = []
var connectedCount = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size/2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !moving and !popped:
		searchOtherPuyos()
		if connectedCount > 3:
			pop()

# 'Gravity' for the puyos that works similarly to the actual games, also stays within the tilemap
func _on_gravity_timer_timeout():
	if(!$RayBottom.is_colliding()):
		position += Vector2.DOWN * tile_size
		moving = true
	else:
		moving = false

func searchOtherPuyos():
	connected.clear()
	if $RayTop.is_colliding() and $RayTop.get_collider() is Area2D:
		if $RayTop.get_collider().type == "RED":
			connected.append("TOP")
	if $RayBottom.is_colliding() and $RayBottom.get_collider() is Area2D:
		if $RayBottom.get_collider().type == "RED":
			connected.append("BOTTOM")
	if $RayLeft.is_colliding() and $RayLeft.get_collider() is Area2D:
		if $RayLeft.get_collider().type == "RED":
			connected.append("LEFT")
	if $RayRight.is_colliding() and $RayRight.get_collider() is Area2D:
		if $RayRight.get_collider().type == "RED":
			connected.append("RIGHT")
	updateSpriteFrame()

# Update the sprite animation depending on how the its connected to other puyos
func updateSpriteFrame():
	if(connected.size() < 1):
		$PuyoSprites.play("default")
	elif(connected.size() == 1 and "TOP" in connected):
		$PuyoSprites.play("joined_above")
	elif(connected.size() == 1 and "BOTTOM" in connected):
		$PuyoSprites.play("joined_below")
	elif(connected.size() == 1 and "LEFT" in connected):
		$PuyoSprites.play("joined_left")
	elif(connected.size() == 1 and "RIGHT" in connected):
		$PuyoSprites.play("joined_right")
	elif(connected.size() == 2 and "TOP" in connected and "BOTTOM" in connected):
		$PuyoSprites.play("joined_above_below")
	elif(connected.size() == 2 and "TOP" in connected and "LEFT" in connected):
		$PuyoSprites.play("joined_above_left")
	elif(connected.size() == 2 and "TOP" in connected and "RIGHT" in connected):
		$PuyoSprites.play("joined_above_right")
	elif(connected.size() == 2 and "BOTTOM" in connected and "RIGHT" in connected):
		$PuyoSprites.play("joined_below_right")
	elif(connected.size() == 2 and "BOTTOM" in connected and "LEFT" in connected):
		$PuyoSprites.play("joined_below_left")
	elif(connected.size() == 2 and "LEFT" in connected and "RIGHT" in connected):
		$PuyoSprites.play("joined_left_right")
	elif(connected.size() == 3 and "TOP" in connected and "BOTTOM" in connected and "LEFT" in connected):
		$PuyoSprites.play("joined_above_below_left")
	elif(connected.size() == 3 and "TOP" in connected and "BOTTOM" in connected and "RIGHT" in connected):
		$PuyoSprites.play("joined_above_below_right")
	elif(connected.size() == 3 and "TOP" in connected and "LEFT" in connected and "RIGHT" in connected):
		$PuyoSprites.play("joined_above_left_right")
	elif(connected.size() == 3 and "BOTTOM" in connected and "LEFT" in connected and "RIGHT" in connected):
		$PuyoSprites.play("joined_below_left_right")
	else:
		$PuyoSprites.play("joined_all")

# Starts timers to animate the puyo being popped and removes them
func pop():
	popped = true
	$PuyoSprites.play("popped_start")
	$PoppedPreTimer.start()
	$PoppedTimer.start()

func _on_popped_pre_timer_timeout():
	if($PuyoSprites.visible):
		$PuyoSprites.visible = false
	else:
		$PuyoSprites.visible = true
	
	if $PoppedPreTimer.wait_time > 0.01:
		$PoppedPreTimer.wait_time = $PoppedPreTimer.wait_time - 0.01
		$PoppedPreTimer.start()


func _on_popped_timer_timeout():
	$PoppedPreTimer.stop()
	$PuyoSprites.visible = true
	$PuyoSprites.play("popped_end")
	await $PuyoSprites.animation_finished
	queue_free()
