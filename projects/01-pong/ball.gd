extends CharacterBody2D


@export_range(25,800) var speed := 600.0
var current_position = 0
var target_position = 0
var direction

# CharacterBody2D.move_and_collide(velocity)

func _ready() -> void:
	var left_or_right = randi_range(0,1)
	if left_or_right == 0:
		direction = Vector2((randi() % - 100 - 1), (randi_range(-100, 100))).normalized()
	else:
		direction = Vector2((randi() % + 100 + 1), (randi_range(-100, 100))).normalized()



func _physics_process(delta: float) -> void:
	position += delta * (direction * speed)
	move_and_slide()
