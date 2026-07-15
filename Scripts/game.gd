extends Node3D


const PROTO_CONTROLLER = preload("uid://bs72ogkvdd7d6")
var players: Array[CharacterBody3D]









func _ready():
	Networking.host_created.connect(_on_host_created)
	multiplayer.peer_connected.connect(_peer_connected)
	
func _on_host_created():
	pass
	
func _peer_connected(peer_id:int):
	pass


func _on_button_pressed() -> void:
	$CanvasLayer/host.disabled = true
	Networking.host_lobby()


func _on_start_pressed() -> void:
	$CanvasLayer/host.hide()
	$CanvasLayer/start.hide()
	if !multiplayer.is_server():
		return
	spawn_player.rpc(multiplayer.get_unique_id())
	
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

	$players.add_child(player)
	initialize_player(player)
