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
				
				if object.is_in_group("tool"):
					root.hasTool = true
					holding_is_tool = true
				else:
					holding_is_tool = false
				
				# Call the RPC to tell ALL players (and the host) to update this item
				rpc("update_item_network_state", holding.get_path(), multiplayer.get_unique_id(), holding_is_tool)

	# 2. Throw the item
	elif Input.is_action_just_pressed("throw") and holding != null:
		if holding_is_tool:
			root.hasTool = false
			
		var throw_direction = -cam.global_basis.z.normalized()
		holding.linear_velocity = throw_direction * throw_power
		
		# Tell all players to return authority to Host (1) and unfreeze it
		rpc("update_item_network_state", holding.get_path(), 1, false)
		holding = null
		
	# 3. Drop the item
	elif Input.is_action_just_pressed("drop") and holding != null:
		if holding_is_tool:
			root.hasTool = false
			
		holding.linear_velocity = Vector3(0, 3, 0)
		
		# Tell all players to return authority to Host (1) and unfreeze it
		rpc("update_item_network_state", holding.get_path(), 1, false)
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


# --- NETWORK SYNCHRONIZATION ---

# "any_peer" allows clients to call this on the server.
# "call_local" ensures the person who triggered it also runs the code.
# "reliable" ensures the packet doesn't get dropped.
@rpc("any_peer", "call_local", "reliable")
func update_item_network_state(item_path: NodePath, new_authority_id: int, should_freeze: bool):
	# Safely get the item using its path in the scene tree
	var item = get_node_or_null(item_path)
	
	if item and item is RigidBody3D:
		# Now everyone universally agrees who owns it
		item.set_multiplayer_authority(new_authority_id)
		# And everyone universally agrees if physics are turned off for it
		item.freeze = should_freeze
