extends Area2D

var tile_size = 58

# Called when the node enters the scene tree for the first time.
func _ready():
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size/2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_gravity_timer_timeout():
	if(!$RayBottom.is_colliding()):
		position += Vector2.DOWN * tile_size

