extends Control

signal restartPressed

# Called when the node enters the scene tree for the first time.
func _ready():
	$Restart.visible = false
	clearNuisanceQueue("Player1")
	clearNuisanceQueue("Player2")
	await get_tree().create_timer(0.01).timeout
	$Player1.process_mode = Node.PROCESS_MODE_DISABLED
	$Player2.process_mode = Node.PROCESS_MODE_DISABLED
	$UIAnims/Anims.play("matchStart")
	await $UIAnims/Anims.animation_finished
	$Player1.process_mode = Node.PROCESS_MODE_INHERIT
	$Player2.process_mode = Node.PROCESS_MODE_INHERIT

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	displayNuisanceQueue("Player1")
	displayNuisanceQueue("Player2")
	$P1Queue.text = str($Player1.nuisanceQueue)
	$P2Queue.text = str($Player2.nuisanceQueue)

func _on_restart_pressed():
	emit_signal("restartPressed")

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
		playDamageSoundEffects(damage)

func _on_player_2_send_damage(damage):
	if damage > 0:
		$Player1.queueNuisance(damage)
		playDamageSoundEffects(damage)

func clearNuisanceQueue(player):
	for sprite in get_node(player + "/NuisanceQueue").get_children():
		sprite.visible = false

func displayNuisanceQueue(player):
	var nuisanceQueueSprites = get_node(player + "/NuisanceQueue").get_children()
	var nuisanceToShow = get_node(player).nuisanceQueue
	var spritesUsed = 0
	clearNuisanceQueue(player)
	while nuisanceToShow > 0 and spritesUsed < 6:
		if nuisanceToShow < 6:
			nuisanceQueueSprites[spritesUsed].visible = true
			nuisanceQueueSprites[spritesUsed].play("small")
			spritesUsed += 1
			nuisanceToShow -= 1
		elif nuisanceToShow >= 6 and nuisanceToShow < 30:
			nuisanceQueueSprites[spritesUsed].visible = true
			nuisanceQueueSprites[spritesUsed].play("large")
			spritesUsed += 1
			nuisanceToShow -= 6
		elif nuisanceToShow >= 30 and nuisanceToShow < 180:
			nuisanceQueueSprites[spritesUsed].visible = true
			nuisanceQueueSprites[spritesUsed].play("rock")
			spritesUsed += 1
			nuisanceToShow -= 30
		elif nuisanceToShow >= 180 and nuisanceToShow < 360:
			nuisanceQueueSprites[spritesUsed].visible = true
			nuisanceQueueSprites[spritesUsed].play("star")
			spritesUsed += 1
			nuisanceToShow -= 180
		elif nuisanceToShow >= 360 and nuisanceToShow < 720:
			nuisanceQueueSprites[spritesUsed].visible = true
			nuisanceQueueSprites[spritesUsed].play("moon")
			spritesUsed += 1
			nuisanceToShow -= 360
		elif nuisanceToShow >= 720 and nuisanceToShow < 1440:
			nuisanceQueueSprites[spritesUsed].visible = true
			nuisanceQueueSprites[spritesUsed].play("crown")
			spritesUsed += 1
			nuisanceToShow -= 720
		elif nuisanceToShow >= 1440:
			nuisanceQueueSprites[spritesUsed].visible = true
			nuisanceQueueSprites[spritesUsed].play("comet")
			spritesUsed += 1
			nuisanceToShow -= 1440

func playDamageSoundEffects(damage):
	if damage < 12:
		$SoundEffects/Attack1.play()
	elif damage >= 12 and damage < 30:
		$SoundEffects/Attack2.play()
	elif damage >= 30 and damage < 72:
		$SoundEffects/Attack3.play()
	else:
		$SoundEffects/Attack4.play()
		
