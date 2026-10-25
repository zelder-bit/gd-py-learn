extends ColorRect

@export_range(50,250) var speed := 200.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print('Ready')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += delta * (Vector2.RIGHT * speed)
	
