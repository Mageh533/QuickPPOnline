extends Control

signal gameEnd

var matchStarted = false
var timeOutEffectCooldown = false

var poppedPuyos = 0

@onready var nuisanceQueueSprites = $GarbageSentPanel/NuisanceQueue.get_children()

# Called when the node enters the scene tree for the first time.
func _ready():
	$GameModePanel/ModeContainer/Mode.text = GameManager.soloInfo.gamemode
	clearNuisanceQueue()
	await get_tree().create_timer(0.05).timeout
	$PuyoGame.process_mode = Node.PROCESS_MODE_DISABLED
	$UIAnims/AnimationPlayer.play("Start")
	await $UIAnims/AnimationPlayer.animation_finished
	$PuyoGame.process_mode = Node.PROCESS_MODE_INHERIT
	matchStarted = true
	GameManager.soloInfo.active = true
	GameManager.soloInfo.matchTime = GameManager.soloMatchSettings.timeLimit

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if $PuyoGame.currentChain > GameManager.soloInfo.maxChain:
		GameManager.soloInfo.maxChain = $PuyoGame.currentChain
	$InfoPanel/VBox/Chain/MaxChain.text = str(GameManager.soloInfo.maxChain)
	var player = get_tree().get_nodes_in_group("Player")[0]
	GameManager.soloInfo.speed = player.fallSpeed / 10
	$InfoPanel/VBox/Speed/Speed.text = str(GameManager.soloInfo.speed)
	if matchStarted:
		if GameManager.soloMatchSettings.timeLimit > 0:
			GameManager.soloInfo.matchTime -= delta
			if GameManager.soloInfo.matchTime < 10 and GameManager.soloInfo.matchTime > 0:
				$InfoPanel/VBox/Time/Time.modulate = Color.YELLOW
				if !timeOutEffectCooldown:
					timeOutEffectCooldown = true
					$TimeOutFX.start()
					$SoundEffects/Timeout.play()
			elif GameManager.soloInfo.matchTime <= 0:
				gameOver()
		else:
			GameManager.soloInfo.matchTime += delta
		var seconds = fmod(GameManager.soloInfo.matchTime, 60)
		var minutes = floor(GameManager.soloInfo.matchTime / 60)
		$InfoPanel/VBox/Time/Time.text = str(minutes) + ":" + str(seconds).pad_zeros(2).pad_decimals(2)

func gameOver():
	matchStarted = false
	if GameManager.soloMatchSettings.timeLimit > 0:
		$SoundEffects/TimeoutEnd.play()
		GameManager.soloInfo.matchTime = 0
		$PuyoGame.process_mode = Node.PROCESS_MODE_DISABLED
		await get_tree().create_timer(1).timeout
		$PuyoGame.process_mode = Node.PROCESS_MODE_INHERIT
	$PuyoGame/GameAnims.play("lose")
	$UIAnims/AnimationPlayer.play("End")
	await $UIAnims/AnimationPlayer.animation_finished
	$PuyoGame.process_mode = Node.PROCESS_MODE_DISABLED
	emit_signal("gameEnd")

func _on_puyo_game_lost():
	gameOver()

func clearNuisanceQueue():
	for sprite in nuisanceQueueSprites:
		sprite.hide()

func _on_puyo_game_send_damage(damage):
	var nuisanceToShow = damage
	clearNuisanceQueue()
	GameManager.nuisanceDisplayHelper(nuisanceQueueSprites, nuisanceToShow, 6)
	if GameManager.soloMatchSettings.sendNuisanceToSelf:
		$PuyoGame.queueNuisance(damage)

func _on_time_out_fx_timeout():
	timeOutEffectCooldown = false

func _on_puyo_game_send_popped_puyos(puyos):
	poppedPuyos += puyos
	if !GameManager.soloMatchSettings.fixedSpeed:
		if poppedPuyos > 30:
			poppedPuyos = 0
			get_tree().get_nodes_in_group("Player")[0].fallSpeed += 10
			$SoundEffects/ChallengeUp.play()
