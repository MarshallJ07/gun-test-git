extends RigidBody3D

var id: int

func _ready() -> void:
	$Timer.start()

func _physics_process(delta: float) -> void:
	if multiplayer.get_unique_id() == id:
		update_cam()
		
func update_cam() -> void:
	get_parent().get_parent().get_node("players").get_node(str(id)).global_position = global_position
	if linear_velocity.length() < 1.5 and $Timer.is_stopped():
		delete_ragdoll.rpc()
		
@rpc("any_peer","call_local","reliable")
func delete_ragdoll() -> void:
	get_parent().get_parent().get_node("players").get_node(str(id)).show()
	get_parent().get_parent().get_node("players").get_node(str(id)).can_move = true
	get_parent().get_parent().get_node("players").get_node(str(id)).can_shoot = true
	queue_free()
