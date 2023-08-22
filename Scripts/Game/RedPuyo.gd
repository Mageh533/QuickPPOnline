extends Area2D

signal puyoConnected

var tile_size = 58

var active = false
var moving = true
var popped = false
@export var type = ""
var connectedPositions = []
var connected = []

func _ready():
	basicSetup()

func _process(_delta):
	if !moving and !popped:
		await searchOtherPuyos()

# 'Gravity' for the puyos that works similarly to the actual games, also stays within the tilemap
func _on_gravity_timer_timeout():
	if(!$RayBottom.is_colliding()):
		position += Vector2.DOWN * tile_size
		moving = true
	else:
		moving = false

# Searches for other puyos that are connectedPositions, adds to the array if it finds one to update the spritesheet
# As well as running a recursive function to find out if the other puyos are connectedPositions to others and keeps count
# If it counts 4 or more it will then pop
func searchOtherPuyos():
	connectedPositions.clear()
	connected.clear()
	if $RayTop.is_colliding() and $RayTop.get_collider() is Area2D:
		if $RayTop.get_collider().type == type:
			connectedPositions.append("TOP")
			connected.append($RayTop.get_collider())
	if $RayBottom.is_colliding() and $RayBottom.get_collider() is Area2D:
		if $RayBottom.get_collider().type == type:
			connectedPositions.append("BOTTOM")
			connected.append($RayBottom.get_collider())
	if $RayLeft.is_colliding() and $RayLeft.get_collider() is Area2D:
		if $RayLeft.get_collider().type == type:
			connectedPositions.append("LEFT")
			connected.append($RayLeft.get_collider())
	if $RayRight.is_colliding() and $RayRight.get_collider() is Area2D:
		if $RayRight.get_collider().type == type:
			connectedPositions.append("RIGHT")
			connected.append($RayRight.get_collider())
	
	updateSpriteFrame()
	
	if connectedPositions.size() > 0:
		emit_signal("puyoConnected")

# Update the sprite animation depending on how the its connectedPositions to other puyos
func updateSpriteFrame():
	if(connectedPositions.size() < 1):
		$PuyoSprites.play("default")
	elif(connectedPositions.size() == 1 and "TOP" in connectedPositions):
		$PuyoSprites.play("joined_above")
	elif(connectedPositions.size() == 1 and "BOTTOM" in connectedPositions):
		$PuyoSprites.play("joined_below")
	elif(connectedPositions.size() == 1 and "LEFT" in connectedPositions):
		$PuyoSprites.play("joined_left")
	elif(connectedPositions.size() == 1 and "RIGHT" in connectedPositions):
		$PuyoSprites.play("joined_right")
	elif(connectedPositions.size() == 2 and "TOP" in connectedPositions and "BOTTOM" in connectedPositions):
		$PuyoSprites.play("joined_above_below")
	elif(connectedPositions.size() == 2 and "TOP" in connectedPositions and "LEFT" in connectedPositions):
		$PuyoSprites.play("joined_above_left")
	elif(connectedPositions.size() == 2 and "TOP" in connectedPositions and "RIGHT" in connectedPositions):
		$PuyoSprites.play("joined_above_right")
	elif(connectedPositions.size() == 2 and "BOTTOM" in connectedPositions and "RIGHT" in connectedPositions):
		$PuyoSprites.play("joined_below_right")
	elif(connectedPositions.size() == 2 and "BOTTOM" in connectedPositions and "LEFT" in connectedPositions):
		$PuyoSprites.play("joined_below_left")
	elif(connectedPositions.size() == 2 and "LEFT" in connectedPositions and "RIGHT" in connectedPositions):
		$PuyoSprites.play("joined_left_right")
	elif(connectedPositions.size() == 3 and "TOP" in connectedPositions and "BOTTOM" in connectedPositions and "LEFT" in connectedPositions):
		$PuyoSprites.play("joined_above_below_left")
	elif(connectedPositions.size() == 3 and "TOP" in connectedPositions and "BOTTOM" in connectedPositions and "RIGHT" in connectedPositions):
		$PuyoSprites.play("joined_above_below_right")
	elif(connectedPositions.size() == 3 and "TOP" in connectedPositions and "LEFT" in connectedPositions and "RIGHT" in connectedPositions):
		$PuyoSprites.play("joined_above_left_right")
	elif(connectedPositions.size() == 3 and "BOTTOM" in connectedPositions and "LEFT" in connectedPositions and "RIGHT" in connectedPositions):
		$PuyoSprites.play("joined_below_left_right")
	else:
		$PuyoSprites.play("joined_all")

# Starts timers to animate the puyo blinking and popped and removes them
func pop():
	if !popped:
		popped = true
		$PoppedPreTimer.start()
		$PoppedTimer.start()

func basicSetup():
	position = position.snapped(Vector2.ONE * tile_size)
	position += -Vector2.ONE * tile_size/2

func _on_popped_pre_timer_timeout():
	if($PuyoSprites.visible):
		$PuyoSprites.visible = false
	else:
		$PuyoSprites.visible = true
	
	if $PoppedPreTimer.wait_time > 0.01:
		$PoppedPreTimer.wait_time = $PoppedPreTimer.wait_time - 0.02
		$PoppedPreTimer.start()


func _on_popped_timer_timeout():
	$PoppedPreTimer.stop()
	$PuyoSprites.visible = true
	$PuyoSprites.play("popped_start")
	await get_tree().create_timer(0.1).timeout
	$PuyoSprites.play("popped_end")
	await $PuyoSprites.animation_finished
	queue_free()
