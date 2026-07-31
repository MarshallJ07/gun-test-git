extends Node3D

var holding: RigidBody3D
var holding_is_tool: bool = false 

var throw_power: float = 15.0 
# pull_power and rotate_power removed because frozen RigidBody3Ds ignore physics velocities.

@onready var root: CharacterBody3D = $".."
@onready var cam: Camera3D = $Camera3D
@onready var raycast: RayCast3D = $Camera3D/RayCast3D
@onready var hand: Node3D = $hand

@rpc("any_peer","call_local","reliable")
func speed_change(objectName) -> void:
	if objectName == "up":
		EventBus.targetSpeed += 25
		EventBus.atStation = false
		if EventBus.targetSpeed > EventBus.maxSpeed:
			EventBus.targetSpeed = EventBus.maxSpeed
		EventBus.statChange.emit()
	elif objectName == "down":
		EventBus.targetSpeed -= 25
		if EventBus.targetSpeed < 0:
			EventBus.targetSpeed = 0
		EventBus.statChange.emit()

func _physics_process(delta: float) -> void:
	
	if Input.is_action_just_pressed("Interact"):
		if raycast.is_colliding():
			var object = raycast.get_collider()
			if object.is_in_group("button"):
				speed_change.rpc(object.name)
	
	# 1. Pick up the item
	if Input.is_action_just_pressed("pickup") and holding == null:
		if raycast.is_colliding():
			var object = raycast.get_collider()
			if object is RigidBody3D and object.is_in_group("item"):
				holding = object
				holding.add_collision_exception_with(root)
				
				if object.is_in_group("tool"):
					root.hasTool = true
					holding_is_tool = true
				else:
					holding_is_tool = false
				
				# Pass `true` as the should_freeze argument so ALL items freeze when held
				rpc("update_item_network_state", holding.get_path(), multiplayer.get_unique_id(), true, Vector3.ZERO)

	# 2. Throw the item
	elif Input.is_action_just_pressed("throw") and holding != null:
		if holding_is_tool:
			root.hasTool = false
			
		# Calculate the throw velocity
		var throw_direction = -cam.global_basis.z.normalized()
		var throw_vel = throw_direction * throw_power
		
		# Send the velocity TO the server and unfreeze it (`false`)
		rpc("update_item_network_state", holding.get_path(), 1, false, throw_vel)
		holding = null
		
	# 3. Drop the item
	elif Input.is_action_just_pressed("drop") and holding != null:
		if holding_is_tool:
			root.hasTool = false
			
		# Calculate the drop velocity
		var drop_vel = Vector3(0, 3, 0)
		
		# Send the drop velocity TO the server and unfreeze it (`false`)
		rpc("update_item_network_state", holding.get_path(), 1, false, drop_vel)
		holding = null

	# 4. Hold and move
	if holding != null:
		# Because the item is now frozen, it cannot be moved using velocity.
		# We snap ALL held items directly to the hand's position and rotation.
		holding.global_transform = hand.global_transform


# --- NETWORK SYNCHRONIZATION ---

@rpc("any_peer", "call_local", "reliable")
func update_item_network_state(item_path: NodePath, new_authority_id: int, should_freeze: bool, new_velocity: Vector3):
	var item = get_node_or_null(item_path)
	
	if item and item is RigidBody3D:
		item.set_multiplayer_authority(new_authority_id)
		item.freeze = should_freeze
		
		# Universally apply the velocity at the exact moment authority changes
		if new_velocity != Vector3.ZERO:
			item.linear_velocity = new_velocity
