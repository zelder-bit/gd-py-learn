extends CharacterBody2D


@export_range(50,4000) var speed := 600.0


var ball_collision : KinematicCollision2D
var ball_velocity : Vector2
var number_of_bounces = {
	"paddle_hit" : 0,
	"wall_hit" : 0,
	"total" : 0
}

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
		var ball_collider = ball_collision.get_collider()
		if (ball_collider.is_in_group("paddle")):
			number_of_bounces.paddle_hit = number_of_bounces.paddle_hit + 1
			number_of_bounces.total = number_of_bounces.total + 1
		else:
			number_of_bounces.wall_hit = number_of_bounces.wall_hit + 1
			number_of_bounces.total	= number_of_bounces.total + 1
		#keep velocity on bounce:
		ball_velocity = ball_velocity.bounce(ball_collision.get_normal())
		
		#print / debug shit
		print("This is the ball_collider variable: " + str(ball_collider))
		print("Counter: Paddle # " + str(number_of_bounces.paddle_hit) + 
			" Wall # " + str(number_of_bounces.wall_hit) + 
			" Total # " + str(number_of_bounces.total))
		
	
