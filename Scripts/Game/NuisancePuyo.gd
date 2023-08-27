extends Area2D

var tile_size = 58

var type = "Nuisance"

var active = false
var popped = false

# Called when the node enters the scene tree for the first time.
func _ready():
	active = true
	position = position.snapped(Vector2.ONE * tile_size)
	position += -Vector2.ONE * tile_size/2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func pop():
	if !popped:
		popped = true
		$PoppedPreTimer.start()
		$PoppedTimer.start()

func _on_gravity_timer_timeout():
	if(!$RayBottom.is_colliding()):
		position += Vector2.DOWN * tile_size

func _on_pre_popped_timer_timeout():
	if($PuyoSprite.visible):
		$PuyoSprite.visible = false
	else:
		$PuyoSprite.visible = true
		
	if $PoppedPreTimer.wait_time > 0.01:
		$PoppedPreTimer.wait_time = $PoppedPreTimer.wait_time - 0.02


func _on_popped_timer_timeout():
	queue_free()
