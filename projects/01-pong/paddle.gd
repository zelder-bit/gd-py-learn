extends CharacterBody2D

@export_range(25,800) var speed := 400.0
# @export_enum("player1_up", "player2_up") var paddle_up: Array[String]
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin") var up_action: String = "player1_up"
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin") var down_action: String = "player1_down"

var paddle_Size
var screen_Size
var top_height
var bottom_height

func _ready() -> void:
	screen_Size = get_viewport_rect().size
	paddle_Size = $paddle_shape.size.y
	top_height = 0
	bottom_height = screen_Size.y - paddle_Size
	
	
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	position.y = clampf(position.y, top_height, bottom_height)
	if (Input.is_action_pressed(up_action)):
		position += delta * (Vector2.UP * speed)
	if (Input.is_action_pressed(down_action)):
		position += delta * (Vector2.DOWN * speed)
