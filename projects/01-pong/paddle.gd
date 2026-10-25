extends CharacterBody2D

@export_range(25,800) var speed := 400.0
# @export_enum("player1_up", "player2_up") var paddle_up: Array[String]
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin") var up_action: String = "player1_up"
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin") var down_action: String = "player1_down"

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	if (Input.is_action_pressed(up_action)):
		position += delta * (Vector2.UP * speed)
	if (Input.is_action_pressed(down_action)):
		position += delta * (Vector2.DOWN * speed)
