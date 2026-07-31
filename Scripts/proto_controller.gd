# ProtoController v1.0 by Brackeys (Train/Moving Platform Relativity Fix)
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = true
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = true

@export var can_shoot : bool = true

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 12.0
## Speed of jump.
@export var jump_velocity : float = 12
## How fast do we run?
@export var sprint_speed : float = 18.0
## How fast do we freefly?
@export var freefly_speed : float = 200.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var hasTool := false

# --- NEW: Reference Frame Variables ---
# local_velocity strictly tracks our input (walking/jumping)
var local_velocity := Vector3.ZERO
# platform_inertia safely stores the train's speed when we jump/fall
var platform_inertia := Vector3.ZERO 

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D


func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	
	# IMPORTANT: We disable Godot's built-in platform velocity addition on leave, 
	# because we are now perfectly maintaining the train's reference frame ourselves mid-air.
	platform_on_leave = PLATFORM_ON_LEAVE_DO_NOTHING
	
	
func _tool_change() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()


func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
		
	# Handle freefly
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		velocity = motion * freefly_speed
		move_and_slide()
		return

	if hasTool and Input.is_action_just_pressed("Interact"):
		animation.play("use tool")

	# Get inputs
	var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
	var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed
	else:
		move_speed = base_speed

	# --- MOVEMENT LOGIC ---
	if is_on_floor():
		# 1. Update our reference frame to match the moving train exactly
		platform_inertia = get_platform_velocity()

		# 2. Handle ground movement (This modifies local_velocity ONLY)
		if can_move:
			if move_dir:
				local_velocity.x = move_dir.x * move_speed
				local_velocity.z = move_dir.z * move_speed
			else:
				local_velocity.x = move_toward(local_velocity.x, 0, move_speed)
				local_velocity.z = move_toward(local_velocity.z, 0, move_speed)
		else:
			local_velocity.x = 0
			local_velocity.z = 0

		# 3. Jump (Applies to our local space)
		if can_jump and Input.is_action_just_pressed(input_jump):
			local_velocity.y = jump_velocity

		# When on the ground, Godot natively adds the platform's speed during move_and_slide().
		# We ONLY pass it our relative movement.
		velocity = local_velocity

	else:
		# 1. Apply Gravity
		if has_gravity:
			local_velocity += get_gravity() * delta
			
		# 2. Apply Air steering & friction to our local velocity
		if can_move:
			if move_dir:
				var target_x = move_dir.x * move_speed
				var target_z = move_dir.z * move_speed
				local_velocity.x = move_toward(local_velocity.x, target_x, move_speed * delta * 2.0)
				local_velocity.z = move_toward(local_velocity.z, target_z, move_speed * delta * 2.0)
			else:
				local_velocity.x = move_toward(local_velocity.x, 0, base_speed * delta * 1.0)
				local_velocity.z = move_toward(local_velocity.z, 0, base_speed * delta * 1.0)

		# In the air, we detach from the ground. We MUST manually add the train's inertia 
		# so we don't fall backward while in mid-air.
		velocity = local_velocity + platform_inertia

	# Perform the actual move
	move_and_slide()

	# --- CLEANUP POST-MOVE ---
	# Update local_velocity based on collision results (e.g., hitting a wall)
	if is_on_floor():
		local_velocity = velocity 
	else:
		# Extract the train's inertia back out so our internal calculations stay perfectly relative
		local_velocity = velocity - platform_inertia


## Rotate us to look around.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

## Checks if some Input Actions haven't been created.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "use tool":
		if raycast.is_colliding():
			var object = raycast.get_collider()
			EventBus.repairing.emit(object, 10)
