extends Node3D


const PROTO_CONTROLLER = preload("uid://bs72ogkvdd7d6")
var players: Array[CharacterBody3D]







var ids = []

func _ready():
	Networking.host_created.connect(_on_host_created)
	multiplayer.peer_connected.connect(_peer_connected)
	
	
	
	
func _on_host_created():
	pass
	
func _peer_connected(peer_id:int):
	ids.append(peer_id)


func _on_button_pressed() -> void:
	$CanvasLayer/host.disabled = true
	Networking.host_lobby()


func _on_start_pressed() -> void:
	if !multiplayer.is_server():
		return
	spawn_player.rpc(multiplayer.get_unique_id())
	for id in ids:
		spawn_player.rpc(id)
	hide_buttons.rpc()
	
@rpc("any_peer","call_local","reliable")
func hide_buttons() -> void:
	$CanvasLayer/host.hide()
	$CanvasLayer/start.hide()
	
	
func initialize_player(player:CharacterBody3D):

	player.global_position = $spawnpoint.global_position

	for other in players:
		player.add_collision_exception_with(other)
		other.add_collision_exception_with(player)

	players.append(player)
	
@rpc("authority","call_local","reliable")
func spawn_player(peer_id:int):
	$CanvasLayer/waiting.hide()
	var player := PROTO_CONTROLLER.instantiate()
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)
	if peer_id == multiplayer.get_unique_id():
		player.get_node("Head").get_child(0).current = true
	$players.add_child(player)
	initialize_player(player)
	player.shoot_requested.connect(_on_player_shoot_requested)
	
	
func _on_player_shoot_requested(playerTransform: Transform3D, cameraTransform: Transform3D, peer_id: int):
	spawn_bullet_everywhere.rpc(playerTransform, cameraTransform, peer_id)
	
@rpc("authority","call_local","reliable")
func spawn_bullet_everywhere(playerTransform: Transform3D, cameraTransform: Transform3D, peer_id: int) -> void:
	var bullet = preload("res://Scenes/bullet.tscn").instantiate()
	bullet.set_multiplayer_authority(1)
	bullet.global_transform = playerTransform
	bullet.id = peer_id
	$bullets.add_child(bullet)
	var direction = -playerTransform.basis.z
	direction.y = -cameraTransform.basis.z.y
	direction = direction.normalized()
	bullet.apply_central_impulse(direction * 100)
