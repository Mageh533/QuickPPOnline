extends Control

signal restartGame
signal gameEnd

var matchStarted = false

var player1ChainDamage = 0
var player2ChainDamage = 0
var player1Attacked : bool = false
var player2Attacked : bool = false

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
		@warning_ignore("integer_division")
		var minutes = int(GameManager.matchInfo.matchTime) / 60
		$MatchTimer.text = str(minutes).pad_zeros(2) + ":" + str(int(GameManager.matchInfo.matchTime) % 60).pad_zeros(2)
	
	if player1Attacked or player2Attacked:
		playChainAttackEffects()
	else:
		player1ChainDamage = 0
		player2ChainDamage = 0
		get_tree().create_tween().tween_property($UIAnims/ChainAttackPanel, "modulate:a", 0, 1)

func roundEnd(winner):
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
	$UIAnims/Player1EndText.play("Lose")
	await $Player1/AnimationPlayer.animation_finished
	$Player1.process_mode = Node.PROCESS_MODE_DISABLED
	$Player2.process_mode = Node.PROCESS_MODE_DISABLED
	GameManager.matchInfo.p2Wins += 1
	roundEnd(2)

func _on_player_2_lost():
	matchStarted = false
	$SoundEffects/Lose.play()
	$Player2/AnimationPlayer.play("lose")
	$UIAnims/Player2EndText.play("Lose")
	await $Player2/AnimationPlayer.animation_finished
	$Player2.process_mode = Node.PROCESS_MODE_DISABLED
	$Player1.process_mode = Node.PROCESS_MODE_DISABLED
	GameManager.matchInfo.p1Wins += 1
	roundEnd(1)

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
	clearNuisanceQueue(player)
	GameManager.nuisanceDisplayHelper(nuisanceQueueSprites, nuisanceToShow, 6)

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
	@warning_ignore("integer_division")
	var p1DamageToShow = (player1ChainDamage / 2) + 1
	var p2DamageToShow = player2ChainDamage + 1
	$UIAnims/ChainAttackPanel/P1Damage.text = str(player1ChainDamage)
	$UIAnims/ChainAttackPanel/P2Damage.text = str(player2ChainDamage)
	get_tree().create_tween().tween_property($UIAnims/ChainAttackPanel/ChainAttackBar, "max_value", p2DamageToShow, 0.2)
	get_tree().create_tween().tween_property($UIAnims/ChainAttackPanel/ChainAttackBar, "value", p1DamageToShow, 0.2)

func _on_player_1_attacking_damage(attack):
	player1ChainDamage = attack

func _on_player_2_attacking_damage(attack):
	player2ChainDamage = attack

func _on_player_1_attacking(attacking):
	player1Attacked = attacking

func _on_player_2_attacking(attacking):
	player2Attacked = attacking
