extends Node2D

var puyosObjectArray = []
var puyosToPop = [] # To pop all of them at the same time
var connectedPuyos = []
var checkPopTimer = false

func _ready():
	pass

func _process(_delta):
	connectPuyosToGame()

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
			print(connectedPuyos.size())
			puyosToPop.append_array(connectedPuyos)
			
	for puyoToPop in puyosToPop:
		puyoToPop.pop()
	checkPopTimer = false
	
func findOutAllConnected(puyo):
	if puyo.connected.size() > 0 and !connectedPuyos.has(puyo):
		connectedPuyos.append(puyo)
		for otherPuyo in puyo.connected:
			findOutAllConnected(otherPuyo)
