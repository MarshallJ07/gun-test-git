extends Area3D

@onready var game: Node3D = $".."
var fuelWorth := 50
func _physics_process(delta: float) -> void:
	if !multiplayer.is_server():
		return
	for i in get_overlapping_bodies():
		if i.is_in_group("coal"):
			EventBus.fuel += fuelWorth
			EventBus.statChange.emit()
			if EventBus.fuel >= EventBus.maxFuel:
				EventBus.fuel = EventBus.maxFuel
				
			delete_everywhere.rpc(i.name)

@rpc("any_peer","call_local","reliable")
func delete_everywhere(objName:String) -> void:
	
	game.get_node("coal ores").get_node(objName).queue_free()
