extends Panel

@onready var p1Controls = $Controls/P1Controls
@onready var p2Controls = $Controls/P2Controls

var changingControls : bool = false
var controlToChange : String

# Show current controls
func _ready():
	updateCurrentControls()

func updateCurrentControls():
	for control in p1Controls.get_children():
		if control is HBoxContainer:
			var controlAction = control.name
			var button = control.get_children()[1]
			button.text = str(InputMap.action_get_events(controlAction)[0].as_text())
	
	for control in p2Controls.get_children():
		if control is HBoxContainer:
			var controlAction = control.name
			var button = control.get_children()[1]
			button.text = str(InputMap.action_get_events(controlAction)[0].as_text())

func _input(event):
	if event is InputEventKey:
		if changingControls:
			changingControls = false
			GameManager.changeControls(controlToChange, event)
			updateCurrentControls()

# Below are all the control buttons
func _on_p_1_up_pressed():
	controlToChange = "p1_up"
	$Controls/P1Controls/p1_up/p1up.text = "..."
	changingControls = true

func _on_p_1_down_pressed():
	controlToChange = "p1_down"
	$Controls/P1Controls/p1_down/p1down.text = "..."
	changingControls = true

func _on_p_1_left_pressed():
	controlToChange = "p1_left"
	$Controls/P1Controls/p1_left/p1left.text = "..."
	changingControls = true

func _on_p_1_right_pressed():
	controlToChange = "p1_right"
	$Controls/P1Controls/p1_right/p1right.text = "..."
	changingControls = true

func _on_p_1_tleft_pressed():
	controlToChange = "p1_turnLeft"
	$Controls/P1Controls/p1_turnLeft/p1tleft.text = "..."
	changingControls = true

func _on_p_1_tright_pressed():
	controlToChange = "p1_turnRight"
	$Controls/P1Controls/p1_turnRight/p1tright.text = "..."
	changingControls = true

func _on_p_2_up_pressed():
	controlToChange = "p2_up"
	$Controls/P2Controls/p2_up/p2up.text = "..."
	changingControls = true

func _on_p_2_down_pressed():
	controlToChange = "p2_down"
	$Controls/P2Controls/p2_down/p2down.text = "..."
	changingControls = true

func _on_p_2_left_pressed():
	controlToChange = "p2_left"
	$Controls/P2Controls/p2_left/p2left.text = "..."
	changingControls = true

func _on_p_2_right_pressed():
	controlToChange = "p2_right"
	$Controls/P2Controls/p2_right/p2right.text = "..."
	changingControls = true

func _on_p_2_tleft_pressed():
	controlToChange = "p2_turnLeft"
	$Controls/P2Controls/p2_turnLeft/p2tleft.text = "..."
	changingControls = true

func _on_p_2_tright_pressed():
	controlToChange = "p2_turnRight"
	$Controls/P2Controls/p2_turnRight/p2tright.text = "..."
	changingControls = true
