extends Control

signal restartGame
signal gameEnd

var matchStarted = false

var player1ChainDamage = 0
var player2ChainDamage = 0
var player1Attacked : bool = false
var player2Attacked : bool = false
var chainAttackAnims : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	clearNuisanceQueue("Player1")
	clearNuisanceQueue("Player2")
	await get_tree().create_timer(0.05).timeout
	$Player1.process_mode = Node.PROCESS_MODE_DISABLED
	$Player2.process_mode = Node.PROCESS_MODE_DISABLED
	$UIAnims/Anims.play("matchStart")
	await $UIAnims/Anims.animation_finished
	$Player1.process_mode = Node.PROCESS_MODE_INHERIT
	$Player2.process_mode = Node.PROCESS_MODE_INHERIT
	matchStarted = true
	GameManager.matchInfo.matchTime = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	displayNuisanceQueue("Player1")
	displayNuisanceQueue("Player2")
	$P1Queue.text = str($Player1.nuisanceQueue)
	$P2Queue.text = str($Player2.nuisanceQueue)
	$UIAnims/WinsPanel/WinCounterP1.text = str(GameManager.matchInfo.p1Wins)
	$UIAnims/WinsPanel/WinCounterP2.text = str(GameManager.matchInfo.p2Wins)
	$UIAnims/WinsPanel/WinsInfo.text = "First to: " + str(GameManager.matchSettings.roundsToWin)
	if matchStarted:
		GameManager.matchInfo.matchTime += delta
		var minutes = int(GameManager.matchInfo.matchTime) / 60
		$MatchTimer.text = str(minutes).pad_zeros(2) + ":" + str(int(GameManager.matchInfo.matchTime) % 60).pad_zeros(2)
	
	if player1Attacked and player2Attacked:
		chainAttackAnims = true
	elif !player1Attacked and !player2Attacked:
		player1ChainDamage = 0
		player2ChainDamage = 0
	
	if chainAttackAnims:
		playChainAttackEffects()
	else:
		get_tree().create_tween().tween_property($UIAnims/ChainAttackPanel, "modulate:a", 0, 1)

func roundEnd(winner):
	if winner == 1:
		$UIAnims/Player1EndText.text = "You Win!"
		$UIAnims/Player2EndText.text = "You Lose..."
	else:
		$UIAnims/Player1EndText.text = "You Lose..."
		$UIAnims/Player2EndText.text = "You Win!"
	$UIAnims/Anims.play("roundEnd")
	await $UIAnims/Anims.animation_finished
	await get_tree().create_timer(1).timeout
	if GameManager.matchInfo.p1Wins >= GameManager.matchSettings.roundsToWin or GameManager.matchInfo.p2Wins >= GameManager.matchSettings.roundsToWin:
		emit_signal("gameEnd")
	else:
		emit_signal("restartGame")

func _on_player_1_lost():
	matchStarted = false
	$SoundEffects/Lose.play()
	$Player1/AnimationPlayer.play("lose")
	await $Player1/AnimationPlayer.animation_finished
	$Player1.process_mode = Node.PROCESS_MODE_DISABLED
	$Player2.process_mode = Node.PROCESS_MODE_DISABLED
	GameManager.matchInfo.p2Wins += 1
	roundEnd(2)

func _on_player_2_lost():
	matchStarted = false
	$SoundEffects/Lose.play()
	$Player2/AnimationPlayer.play("lose")
	await $Player2/AnimationPlayer.animation_finished
	$Player2.process_mode = Node.PROCESS_MODE_DISABLED
	$Player1.process_mode = Node.PROCESS_MODE_DISABLED
	GameManager.matchInfo.p1Wins += 1
	roundEnd(1)

func _on_player_1_send_damage(damage):
	if damage > 0:
		$Player2.queueNuisance(damage)
		playDamageSoundEffects(damage)
	player1Attacked = false
	if !player2Attacked:
		chainAttackAnims = false

func _on_player_2_send_damage(damage):
	if damage > 0:
		$Player1.queueNuisance(damage)
		playDamageSoundEffects(damage)
	player2Attacked = false
	if !player1Attacked:
		chainAttackAnims = false

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
		

func playChainAttackEffects():
	if $UIAnims/ChainAttackPanel.modulate.a == 0:
		get_tree().create_tween().tween_property($UIAnims/ChainAttackPanel, "modulate:a", 0.6, 1)
	var p1DamageToShow = (player1ChainDamage / 2) + 1
	var p2DamageToShow = player2ChainDamage + 1
	$UIAnims/ChainAttackPanel/P1Damage.text = str(player1ChainDamage)
	$UIAnims/ChainAttackPanel/P2Damage.text = str(player2ChainDamage)
	get_tree().create_tween().tween_property($UIAnims/ChainAttackPanel/ChainAttackBar, "max_value", p2DamageToShow, 0.2)
	get_tree().create_tween().tween_property($UIAnims/ChainAttackPanel/ChainAttackBar, "value", p1DamageToShow, 0.2)

func _on_player_1_attacking_damage(attack):
	player1Attacked = true
	player1ChainDamage = attack

func _on_player_2_attacking_damage(attack):
	player2Attacked = true
	player2ChainDamage = attack
