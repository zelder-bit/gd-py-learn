extends ColorRect

@export_range(50,250) var speed := 200.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print('Ready')
	
# func catch_input(Input) -> void:
#	if Input.is_action_pressed('player1_down'):
#		print('player1_down')
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += delta * (Vector2.RIGHT * speed)
	if (Input.is_action_pressed("player1_down")):
		print("player1 DOWN")
	if (Input.is_action_pressed("player1_up")):
		print("player1 UP")
	if (Input.is_action_pressed("player1_left")):
		print("player1 LEFT")
	if (Input.is_action_pressed("player1_right")):
		print("player1 RIGHT")
