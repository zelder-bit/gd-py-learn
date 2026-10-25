extends CharacterBody2D

@export_range(25,400) var speed := 200.0

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	if (Input.is_action_pressed('player1_up')):
		position += delta * (Vector2.UP * speed)
	if (Input.is_action_pressed('player1_down')):
		position += delta * (Vector2.DOWN * speed)
