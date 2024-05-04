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
const crouching_height = 0.7
const fall_height = 0.8

# weird bug where the player falls even though hes on the floor then does the fall animation on startup
# just fixed it with this brah what can i say...
var first_fall = true

const slide_factor = 0.1
var cached_speed: Vector3

const jump_velocity = 4.5
var just_hit_floor = false

const mouse_sense = 0.3
var lerp_speed = 10.0
var direction = Vector3.ZERO
const turn_weight = 0.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var crouching = false
var intendingToStand = false

enum {
	CAPTURED,
	VISIBLE
}

var mouseMode

func _ready():
	mouseMode = CAPTURED
	
func _process(delta):
	pass
	
	
func _input(event):
	
	
	if Input.is_action_just_pressed("mouse_escape"):
		if mouseMode == CAPTURED:
			mouseMode = VISIBLE
		else:
			mouseMode = CAPTURED
		
	if mouseMode == CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif mouseMode == VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sense))	
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		if cameraCycle[cameraActive] == camera1 or cameraCycle[cameraActive] == camera3_2:
			head.rotation.x = clamp(head.rotation.x,deg_to_rad(-89),deg_to_rad(89))
		elif cameraCycle[cameraActive] == camera3:
			head.rotation.x = clamp(head.rotation.x,deg_to_rad(-60),deg_to_rad(120))
		
var is_crouching = false
var in_the_process_of_crouching = false
var in_the_process_of_uncrouching = false
var in_the_process_of_fall_recovering = false
var tf = 0.0
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

func setFallRecovery():
	tf = 0.0
	in_the_process_of_fall_recovering = true
	current_scale = player.get_scale()

func _physics_process(delta):
	print(velocity)
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
	var local_fall_recovery_speed = 0.1 / delta

	if in_the_process_of_fall_recovering:
		tf += local_fall_recovery_speed * delta
		player.set_scale(Vector3(1.0,lerp(current_scale.y, fall_height, tf),1.0))		
		if tf >= 1.0:
			in_the_process_of_fall_recovering = false
			just_hit_floor = false

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
	elif in_the_process_of_uncrouching and not in_the_process_of_fall_recovering:
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
	
	
	if is_on_floor():
		if not just_hit_floor and abs(cached_speed.y) > 0:
			if not first_fall:
				setFallRecovery()			
				just_hit_floor = true
			if first_fall:
				first_fall = false
		
		if input_dir:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed		
			cached_speed = velocity
		if not input_dir:
			velocity.x = 0.9 * cached_speed.x
			velocity.z = 0.9 * cached_speed.z
			cached_speed = velocity

	else:
		cached_speed = velocity
	
	
	
		
	move_and_slide()
