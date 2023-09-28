extends StaticBody2D

var tile_size = 58

var type = "Nuisance"

var active = false
var popped = false
var moving = false

# Called when the node enters the scene tree for the first time.
func _ready():
	active = true
	position = position.snapped(Vector2.ONE * tile_size)
	position += -Vector2.ONE * tile_size/2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func pop():
	if !popped:
		popped = true
		$PoppedPreTimer.start()
		$PoppedTimer.start()

func _on_gravity_timer_timeout():
	var tween = get_tree().create_tween()
	if(!$RayBottom.is_colliding()):
		moving = true
		position += Vector2.DOWN * tile_size
		tween.tween_property($PuyoSprite, "global_position", global_position, 0.1).set_trans(Tween.TRANS_SINE)
	else:
		tween.kill()
		if moving:
			moving = false
			playSquashAnim(0.5)

func _on_pre_popped_timer_timeout():
	if($PuyoSprite.visible):
		$PuyoSprite.visible = false
	else:
		$PuyoSprite.visible = true
		
	if $PoppedPreTimer.wait_time > 0.01:
		$PoppedPreTimer.wait_time = $PoppedPreTimer.wait_time - 0.02

# Blop!
func playSquashAnim(force):
	var tween = get_tree().create_tween()
	if force > 0.85:
		force = 0.75
	tween.tween_property($PuyoSprite, "scale", Vector2(0.85, force), 0.05)
	tween.tween_property($PuyoSprite, "scale", Vector2(force, 1), 0.05)
	tween.tween_property($PuyoSprite, "scale", Vector2(0.85, 0.85), 0.05)

func _on_popped_timer_timeout():
	queue_free()
