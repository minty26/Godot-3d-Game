extends CharacterBody3D

@onready var head = $head
@onready var standing_collision_shape = $standing_collision_shape
@onready var raycast = $RayCast3D
@onready var player = %player
@onready var camera1 = $"head/eyes/1stPerson"
@onready var camera3 = $"head/3rdPerson"
@onready var camera3_2 = $"head/3rdPerson2"
@onready var cameraCycle = [camera1, camera3, camera3_2]

var cameraActive = -1

var current_speed = 5.0

const walking_speed = 5.0
const sprinting_speed = 8.0
const crouching_speed = 2.8

const jump_velocity = 4.5

const mouse_sense = 0.3

const crouching_height = 0.7

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
var in_the_process_of_crouching = false
var in_the_process_of_uncrouching = false
var t = 0.0
var current_scale : Vector3
var crouch_in_air_count = 0

func setCrouch(yes):
	if yes:
		t = 0.0
		in_the_process_of_crouching = true		
		in_the_process_of_uncrouching = false		
		is_crouching = true
		current_scale = player.get_scale()
	else:
		t = 0.0	
		in_the_process_of_crouching = false
		in_the_process_of_uncrouching = true				
		is_crouching = false		
		current_scale = player.get_scale()		

func _physics_process(delta):
	
	if Input.is_action_just_pressed("perspective"):
		cameraCycle[cameraActive].current = false
		if cameraActive+1 > len(cameraCycle)-1:
			cameraActive = 0
		else:
			cameraActive += 1
		cameraCycle[cameraActive].current = true
	
	if Input.is_action_just_pressed("crouch"):
		if not is_crouching:
			setCrouch(true)
			intendingToStand = false
		
	if Input.is_action_just_released("crouch"):
		print(raycast.get_collider())
		if not raycast.is_colliding():
			setCrouch(false)
			crouch_in_air_count += 1						
		else:
			intendingToStand = true
			
	if not raycast.is_colliding() and intendingToStand:
		setCrouch(false)
		intendingToStand = false
	
	
	#do the crouch
	
	# tweakable
	var local_crouch_speed = 0.1 / delta

	# pressing control and going into crouch
	if in_the_process_of_crouching:
		# progress the 'animation'
		t += local_crouch_speed * delta
		# only go into crouch with camera movement if on the ground
		if is_on_floor():
			player.set_scale(Vector3(1.0,lerp(current_scale.y,crouching_height,t),1.0))
		# if not on the ground, do it a bit differently
		if not is_on_floor():
			# once youve crouched mid air, you stay crouching
			if crouch_in_air_count < 1:
				# resizes you over time but also moves you up at the same rate; crouching you up
				player.set_scale(Vector3(1.0,lerp(current_scale.y,crouching_height,t),1.0))
				player.transform.origin.y += (current_scale.y - (crouching_height * current_scale.y))/4
		if t >= 1.0:
			# once 'animation' complete, disabled ability to uncrouch
			in_the_process_of_crouching = false
			crouch_in_air_count += 1
	
	# released control, and going into a standing position
	elif in_the_process_of_uncrouching:
		if raycast.is_colliding():
			setCrouch(true)		
		# start 'animation'
		t += local_crouch_speed * delta
		if is_on_floor():
			# resizes you back up after landing, or just resizes you normally
			player.set_scale(Vector3(1.0,lerp(current_scale.y,1.0,t),1.0))
		if t >= 1.0:
			# since 'animation' is complete, you're no longer uncrouching; hence just standing
			in_the_process_of_uncrouching = false
	
	
	# if you're not holding crouch, and you're on the ground, resest air crouch counter, and uncrouch
	if not Input.is_action_pressed("crouch") and is_on_floor():
		crouch_in_air_count = 0
		if not raycast.is_colliding():
			setCrouch(false)
		else:
			intendingToStand = true	
		
		
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
	if Input.is_action_just_pressed("jump") and is_on_floor():
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
