extends RigidBody3D

signal request_ragdoll()

var id: int


func _ready() -> void:
	pass 

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return
	if body.name.to_int() != id and body.name != $".".name:
		explode_everywhere.rpc(body.name.to_int())
		
		
@rpc("any_peer", "call_local", "reliable")
func explode_everywhere(peer_id) -> void:
	$particles.restart()
	$CollisionShape3D.queue_free()
	$MeshInstance3D.queue_free()
	$Area3D.queue_free()
	check_player_collisions.rpc_id(1,id)


@rpc("any_peer", "call_local", "reliable")
func check_player_collisions(peer_id) -> void:
	if id != peer_id:
		return
	var space_state = get_world_3d().direct_space_state
	
	var sphere = SphereShape3D.new()
	sphere.radius = 5.0 # <-- Change to your explosion radius

	# Create the query
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(
		Basis.IDENTITY,
		$".".global_position
	)
	query.collide_with_bodies = true
	query.collide_with_areas = false

	query.collision_mask = 1

	var results = space_state.intersect_shape(query)

	for result in results:
		var body = result.collider

		if body is CharacterBody3D:
			print(body.name)
			explode.rpc()
			
@rpc("any_peer", "call_local", "reliable")
func explode() -> void:
	
	var ragdoll = preload("res://Scenes/ragdoll.tscn").instantiate()
	ragdoll.id = id
	ragdoll.set_multiplayer_authority(1)
	get_parent().get_parent().get_node("ragdolls").add_child(ragdoll)
	ragdoll.global_position = get_parent().get_parent().get_node("players").get_node(str(id)).global_position
	ragdoll.apply_impulse((ragdoll.global_position - global_position).normalized() * 25)

	get_parent().get_parent().get_node("players").get_node(str(id)).hide()
	
	
	
	
	
	
	
	
