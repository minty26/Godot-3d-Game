extends CharacterBody3D

@onready var head = $head
@onready var standing_collision_shape = $standing_collision_shape
@onready var raycast = $RayCast3D
@onready var player = %player

var current_speed = 5.0

const walking_speed = 5.0
const sprinting_speed = 8.0
const crouching_speed = 2.8

const jump_velocity = 4.5

const mouse_sense = 0.3

var lerp_speed = 10.0

var direction = Vector3.ZERO

var crouching_depth = -0.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var crouching = false
var intendingToStand = false


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event is InputEventMouseMotion:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
			head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
			head.rotation.x = clamp(head.rotation.x,deg_to_rad(-89),deg_to_rad(89))

var is_crouching = false

func crouchEaseIn():
	pass
	
func crouchEaseOut():
	pass

func setCrouch(yes):
	if yes:
		crouchEaseIn()		
		player.global_scale(Vector3(1,0.5,1))
		is_crouching = true
	else:
		crouchEaseOut()		
		player.global_scale(Vector3(1,2,1))		
		is_crouching = false		


func _physics_process(delta):
	if Input.is_action_just_pressed("crouch"):
		if not is_crouching:
			setCrouch(true)
			intendingToStand = false
		
	if Input.is_action_just_released("crouch"):
		print(raycast.get_collider())
		if not raycast.is_colliding():
			setCrouch(false)
		else:
			intendingToStand = true
			
	if not raycast.is_colliding() and intendingToStand:
		setCrouch(false)
		intendingToStand = false
					
	#if raycast.is_colliding():
	#	current_speed = crouching_speed
	#else:
	#	current_speed = walking_speed
	
	if Input.is_action_pressed("crouch"):
		current_speed = crouching_speed
		#head.position.y = lerp(head.position.y,1.8 + crouching_depth,delta*lerp_speed)
	else:
		
		#head.position.y = lerp(head.position.y,1.8,delta*lerp_speed)
		if Input.is_action_pressed("sprint"):
			current_speed = sprinting_speed
		else:
			current_speed = walking_speed
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerp_speed)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
