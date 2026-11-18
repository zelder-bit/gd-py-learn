extends CharacterBody2D


@export_range(25,800) var speed := 600.0
var ball_direction : Vector2

func _ready() -> void:
	var left_or_right = randi_range(0,1)
	if left_or_right == 0:
		ball_direction = Vector2.from_angle(deg_to_rad(randf_range(125, 235)))
	else:
		ball_direction = Vector2.from_angle(deg_to_rad(randf_range(-55, 55)))
	print("Initial Angle is: " + str(rad_to_deg(ball_direction.angle())))
	

func _physics_process(delta: float) -> void:
	var ball_velocity = (ball_direction * speed)
	move_and_collide(ball_velocity * delta)
	
