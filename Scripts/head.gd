extends Node3D

var holding: RigidBody3D
var holding_is_tool: bool = false # Tracks if the currently held item is a tool

var pull_power: float = 15.0 # Speed it snaps to your hand's position
var rotate_power: float = 15.0 # Speed it snaps to your hand's rotation
var throw_power: float = 15.0 # Strength of the throw

@onready var root: CharacterBody3D = $".."
@onready var cam: Camera3D = $Camera3D
@onready var raycast: RayCast3D = $Camera3D/RayCast3D
@onready var hand: Node3D = $hand

func _physics_process(delta: float) -> void:
	
	# 1. Pick up the item
	if Input.is_action_just_pressed("pickup") and holding == null:
		if raycast.is_colliding():
			var object = raycast.get_collider()
			if object is RigidBody3D and object.is_in_group("item"):
				holding = object
				holding.add_collision_exception_with(root)
				
				# Set authority to the player picking it up
				holding.set_multiplayer_authority(multiplayer.get_unique_id())
				
				# Check if it's a tool to apply the static mesh behavior
				if object.is_in_group("tool"):
					root.hasTool = true
					holding_is_tool = true
					holding.freeze = true # Disables physics so it acts like a mesh
				else:
					holding_is_tool = false

	# 2. Throw the item
	elif Input.is_action_just_pressed("throw") and holding != null:
		if holding_is_tool:
			holding.freeze = false # Turn physics back on before throwing
			root.hasTool = false
			
		var throw_direction = -cam.global_basis.z.normalized()
		holding.linear_velocity = throw_direction * throw_power
		
		# Return authority to host (1) BEFORE clearing the variable
		holding.set_multiplayer_authority(1)
		holding = null
		
	# 3. Drop the item
	elif Input.is_action_just_pressed("drop") and holding != null:
		if holding_is_tool:
			holding.freeze = false # Turn physics back on before dropping
			root.hasTool = false
			
		holding.linear_velocity = Vector3(0, 3, 0)
		
		# Return authority to host (1) BEFORE clearing the variable
		holding.set_multiplayer_authority(1)
		holding = null

	# 4. Hold and move (Executes every frame we are holding something)
	if holding != null:
		
		# If it's a tool, bypass physics entirely and snap perfectly to the hand
		if holding_is_tool:
			holding.global_transform = hand.global_transform
			
		# If it's a regular physics item, use the rubber-band momentum physics
		else:
			# --- Position Physics ---
			var target_pos = hand.global_position
			var current_pos = holding.global_position
			var distance = target_pos - current_pos
			
			holding.linear_velocity = distance * pull_power
			
			# --- Rotation Physics ---
			var target_quat = hand.global_basis.get_rotation_quaternion()
			var current_quat = holding.global_basis.get_rotation_quaternion()
			
			var diff_quat = target_quat * current_quat.inverse()
			var angle = diff_quat.get_angle()
			
			if angle > 0.001:
				var axis = diff_quat.get_axis()
				holding.angular_velocity = axis * angle * rotate_power
			else:
				holding.angular_velocity = Vector3.ZERO
