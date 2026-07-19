extends RigidBody3D

var id: int

func _ready() -> void:
	$Timer.start()

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		update_cam.rpc_id(id)
		
@rpc("authority","call_local","reliable")
func update_cam() -> void:
	get_parent().get_parent().get_node("players").get_node(str(id)).global_position = global_position
	if linear_velocity.length() < 0.5 and $Timer.is_stopped():
		delete_ragdoll.rpc()
		
@rpc("authority","call_local","reliable")
func delete_ragdoll() -> void:
	get_parent().get_parent().get_node("players").get_node(str(id)).show()
	queue_free()
