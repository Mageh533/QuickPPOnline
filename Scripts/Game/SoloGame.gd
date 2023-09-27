extends Control

var matchStarted = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$PuyoGame.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer(0.01).timeout
	$UIAnims/AnimationPlayer.play("Start")
	await $UIAnims/AnimationPlayer.animation_finished
	$PuyoGame.process_mode = Node.PROCESS_MODE_INHERIT
	matchStarted = true

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
