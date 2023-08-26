extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$Restart.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_puyo_game_lost():
	$PuyoGame.set_process(false)
	$Restart.visible = true
	$SoundEffects/Lose.play()
	$PuyoGame/AnimationPlayer.play("lose")

func _on_restart_pressed():
	get_tree().reload_current_scene()
