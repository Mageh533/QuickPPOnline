extends Control

signal gameEnd

var matchStarted = false

@onready var nuisanceQueueSprites = $GarbageSentPanel/NuisanceQueue.get_children()

# Called when the node enters the scene tree for the first time.
func _ready():
	clearNuisanceQueue()
	await get_tree().create_timer(0.05).timeout
	$PuyoGame.process_mode = Node.PROCESS_MODE_DISABLED
	$UIAnims/AnimationPlayer.play("Start")
	await $UIAnims/AnimationPlayer.animation_finished
	$PuyoGame.process_mode = Node.PROCESS_MODE_INHERIT
	matchStarted = true
	GameManager.soloInfo.active = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$GameModePanel/ModeContainer/Mode.text = GameManager.soloInfo.Mode
	if $PuyoGame.currentChain > GameManager.soloInfo.maxChain:
		GameManager.soloInfo.maxChain = $PuyoGame.currentChain
	$InfoPanel/VBox/Chain/MaxChain.text = str(GameManager.soloInfo.maxChain)
	var player = get_tree().get_nodes_in_group("Player")[0]
	GameManager.soloInfo.speed = player.fallSpeed / 10
	$InfoPanel/VBox/Speed/Speed.text = str(GameManager.soloInfo.speed)
	if matchStarted:
		GameManager.soloInfo.matchTime += delta
		var seconds = fmod(GameManager.soloInfo.matchTime, 60)
		var minutes = floor(GameManager.soloInfo.matchTime / 60)
		$InfoPanel/VBox/Time/Time.text = str(minutes) + ":" + str(seconds).pad_zeros(2).pad_decimals(2)


func _on_puyo_game_lost():
	$PuyoGame/GameAnims.play("lose")
	$UIAnims/AnimationPlayer.play("End")
	await $UIAnims/AnimationPlayer.animation_finished
	emit_signal("gameEnd")

func clearNuisanceQueue():
	for sprite in nuisanceQueueSprites:
		sprite.hide()

func _on_puyo_game_send_damage(damage):
	var nuisanceToShow = damage
	clearNuisanceQueue()
	GameManager.nuisanceDisplayHelper(nuisanceQueueSprites, nuisanceToShow, 6)
