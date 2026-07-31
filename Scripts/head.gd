extends Node3D

var holding: RigidBody3D
var holding_is_tool: bool = false 

var throw_power: float = 30.0 

@onready var root: CharacterBody3D = $".."
@onready var cam: Camera3D = $Camera3D
@onready var raycast: RayCast3D = $Camera3D/RayCast3D
@onready var hand: Node3D = $hand

func _physics_process(delta: float) -> void:
	
	# 1. Pick up the item
	if Input.is_action_just_pressed("pickup") and holding == null:
		if raycast.is_colliding():
			var object = raycast.get_collider()
			
			# Check if it's an item, AND make sure no one else is already holding it
			if object is RigidBody3D and object.is_in_group("item"):
				print(object.get("beingHeld"))
				# Safely checks if beingHeld is true. If it doesn't exist, it returns null and lets us pick it up!
				if object.get("beingHeld") == true:
					return # Someone else has it, cancel the pickup!
					
				holding = object
				holding.add_collision_exception_with(root)
				
				if object.is_in_group("tool"):
					root.hasTool = true
					holding_is_tool = true
				else:
					holding_is_tool = false
				
				# Send the ownership change request ONLY to the host (peer id 1)
				# This applies to ALL items picked up!
				if holding.has_method("change_ownership"):
					holding.change_ownership.rpc(true)
				
				rpc("update_item_network_state", holding.get_path(), multiplayer.get_unique_id(), true, Vector3.ZERO)

	# 2. Throw the item
	elif Input.is_action_just_pressed("throw") and holding != null:
		if holding_is_tool:
			root.hasTool = false
			
		var throw_direction = -cam.global_basis.z.normalized()
		var throw_vel = throw_direction * throw_power
		
		# Tell the host we are relinquishing ownership before letting go
		if holding.has_method("change_ownership"):
			holding.change_ownership.rpc(false)
		
		rpc("update_item_network_state", holding.get_path(), 1, false, throw_vel)
		holding = null
		
	# 3. Drop the item
	elif Input.is_action_just_pressed("drop") and holding != null:
		if holding_is_tool:
			root.hasTool = false
			
		var drop_vel = Vector3(0, 3, 0)
		
		# Tell the host we are relinquishing ownership before letting go
		if holding.has_method("change_ownership"):
			holding.change_ownership.rpc(false)
		
		rpc("update_item_network_state", holding.get_path(), 1, false, drop_vel)
		holding = null

	# 4. Hold and move
	if holding != null:
		holding.global_transform = hand.global_transform


# --- NETWORK SYNCHRONIZATION ---
@rpc("any_peer", "call_local", "reliable")
func update_item_network_state(item_path: NodePath, new_authority_id: int, should_freeze: bool, new_velocity: Vector3):
	var item = get_node_or_null(item_path)
	
	if item and item is RigidBody3D:
		item.set_multiplayer_authority(new_authority_id)
		item.freeze = should_freeze
		
		if new_velocity != Vector3.ZERO:
			item.linear_velocity = new_velocity
