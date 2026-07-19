extends RigidBody3D

var id: int

func _ready() -> void:
	$Timer.start()

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		print('updateCam')
		update_cam.rpc()
		
@rpc("authority","call_local","reliable")
func update_cam() -> void:
	print(id)
	get_parent().get_parent().get_node("players").get_node(str(id)).global_position = global_position
	if linear_velocity.length() < 0.5 and $Timer.is_stopped():
		get_parent().get_parent().get_node("players").get_node(str(id)).show()
		queue_free()
