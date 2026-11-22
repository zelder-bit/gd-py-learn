extends CharacterBody2D


@export_range(50,4000) var speed := 600.0


var ball_collision : KinematicCollision2D
var ball_velocity : Vector2
var number_of_bounces := 0

func _ready() -> void:
	var ball_direction : Vector2
	var left_or_right = randi_range(0,1)
	if left_or_right == 0:
		ball_direction = Vector2.from_angle(deg_to_rad(randf_range(125, 235)))
	else:
		ball_direction = Vector2.from_angle(deg_to_rad(randf_range(-55, 55)))
	ball_velocity = ball_direction * speed
	print("This initial Vector2 of ball_velocity is " + str(ball_velocity))
	print("Initial Angle is: " + str(rad_to_deg(ball_direction.angle())))

	
	

func _physics_process(delta: float) -> void:
	ball_collision = move_and_collide(ball_velocity * delta)
	if ball_collision:
		ball_velocity = ball_velocity.bounce(ball_collision.get_normal())
		number_of_bounces = number_of_bounces + 1
		print("Bounce Counter is " + str(number_of_bounces) + " and this bounce had a velocity of: " + str(ball_velocity))
	
