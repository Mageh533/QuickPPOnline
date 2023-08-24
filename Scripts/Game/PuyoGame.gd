extends Node2D

signal sendDamage(damage: int)

var puyosObjectArray = []
var puyosToPop = [] # To pop all of them at the same time
var connectedPuyos = []

var checkPopTimer = false
var soundEffectPlaying = false

var chainCooldown = 0
var currentChain = 0

func _ready():
	pass

func _process(delta):
	connectPuyosToGame()
	if chainCooldown > 0:
		chainCooldown += -delta
		get_tree().get_nodes_in_group("Player")[0].set_process(false)
	else:
		currentChain = 0
		get_tree().get_nodes_in_group("Player")[0].set_process(true)

# Connects their signals
func connectPuyosToGame():
	puyosObjectArray = get_tree().get_nodes_in_group("Puyos")
	for puyo in puyosObjectArray:
		if !puyo.active:
			puyo.active = true
			puyo.puyoConnected.connect(_on_puyo_connected)

# If any puyo emits the signal they are connected it starts the popping timer
func _on_puyo_connected():
	if !checkPopTimer:
		checkPopTimer = true
		$PoppingTimer.start()

# Function checks if 4 or more puyos are connected, if so runs their pop function
func _on_popping_timer_timeout():
	puyosToPop.clear()
	for puyo in puyosObjectArray:
		connectedPuyos.clear()
		findOutAllConnected(puyo)
		
		if connectedPuyos.size() > 3:
			puyosToPop.append_array(connectedPuyos)
			
	if puyosToPop.size() > 0:
		chainCooldown = 2
		currentChain += 1
		playChainSoundEffects()
		
	for puyoToPop in puyosToPop:
		puyoToPop.pop()
	
	checkPopTimer = false

func findOutAllConnected(puyo):
	if puyo.connected.size() > 0 and !connectedPuyos.has(puyo) and !puyo.popped:
		connectedPuyos.append(puyo)
		for otherPuyo in puyo.connected:
			findOutAllConnected(otherPuyo)

func playChainSoundEffects():
	await get_tree().create_timer(0.3).timeout
	if currentChain < 7:
		get_node("ChainSoundEffects/Chain" + str(currentChain)).play()
	else:
		$ChainSoundEffects/Chain7.play()
