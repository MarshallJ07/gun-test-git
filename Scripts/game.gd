extends Node3D


const PROTO_CONTROLLER = preload("uid://bs72ogkvdd7d6")
var players: Array[CharacterBody3D]
var spawnOrder: int
var currentSpawn: int = 0


@onready var screen: Control = $train/SubViewport/screen

var fixables = [
	"brakeSystem",
	"generator",
	"waterPump",
	"boiler",
]

var ids = []

func _ready():
	Networking.host_created.connect(_on_host_created)
	multiplayer.peer_connected.connect(_peer_connected)
	
	set_screen("speed",EventBus.speed)
	set_screen("fuel",EventBus.fuel)
	set_screen("next station",EventBus.nextStation)
	set_screen("distance",EventBus.distance)
	
	EventBus.statChange.connect(_reload_stats)
	
func _reload_stats() -> void:
	set_screen("",null,false)
	
func set_screen(stat:String="", value=null, reload:bool = true) -> void:
	if reload:
		EventBus.stats[stat] = str(value)
	else:
		EventBus.stats = {
		"speed":str(round(EventBus.speed*10)/10),
		"fuel":str(round(EventBus.fuel*10)/10),
		"next station":str(round(EventBus.nextStation*10)/10),
		"distance":str(round(EventBus.distance*10)/10)
	}
	screen.get_child(0).text = (
		"Speed: " + EventBus.stats["speed"] + "Km/h\n
		Boiler fuel: " + EventBus.stats["fuel"] + "L\n
		Next Station: " + EventBus.stats["next station"] + "Km\n
		Distance: " + EventBus.stats["distance"] + "Km\n"
	)


	
func _on_host_created():
	spawnOrder = currentSpawn
	currentSpawn += 1
	
func _peer_connected(peer_id:int):
	ids.append(peer_id)
	if multiplayer.is_server():
		get_spawn_order(currentSpawn)
		currentSpawn += 1
@rpc("any_peer","reliable")
func get_spawn_order(num) -> void:
	spawnOrder = num

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
	player.global_position = $spawnpoints.get_child(spawnOrder).global_position

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


func _physics_process(delta: float) -> void:
	if !multiplayer.is_server():
		return
	
	


func _on_repair_timer_timeout() -> void:
	
	EventBus.repairNode = fixables[randi() % fixables.size()]
	EventBus.needRepairs.emit()
