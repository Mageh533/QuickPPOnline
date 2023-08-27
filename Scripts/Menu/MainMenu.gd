extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	$Restart.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_restart_pressed():
	get_tree().reload_current_scene()

func _on_player_1_lost():
	$SoundEffects/Lose.play()
	$Player1/AnimationPlayer.play("lose")
	await $Player1/AnimationPlayer.animation_finished
	$Player1.process_mode = Node.PROCESS_MODE_DISABLED
	$Player2.process_mode = Node.PROCESS_MODE_DISABLED
	$Restart.visible = true

func _on_player_2_lost():
	$SoundEffects/Lose.play()
	$Player2/AnimationPlayer.play("lose")
	await $Player2/AnimationPlayer.animation_finished
	$Player2.process_mode = Node.PROCESS_MODE_DISABLED
	$Player1.process_mode = Node.PROCESS_MODE_DISABLED
	$Restart.visible = true

func _on_player_1_send_damage(damage):
	if damage > 0:
		$Player2.queueNuisance(damage)

func _on_player_2_send_damage(damage):
	if damage > 0:
		$Player1.queueNuisance(damage)
