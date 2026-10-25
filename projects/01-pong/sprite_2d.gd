extends Sprite2D

var speed = 400

var angular_speed = PI


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta):
	rotation += angular_speed * delta
	var velocity = Vector2.UP.rotated(rotation) * speed
	var testing = str(Vector2.UP.rotated(rotation))
	print('What is Vector2.UP.rotated(rotation)' + testing)
	position += velocity * delta
