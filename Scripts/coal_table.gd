extends Area3D

@onready var game: Node3D = $".."

func _physics_process(delta: float) -> void:
	for i in get_overlapping_bodies():
		if i.is_in_group("coal"):
			delete_everywhere.rpc(i.name)

@rpc("any_peer","call_local","reliable")
func delete_everywhere(objName:String) -> void:
	game.get_node("coal ores").get_node(objName).queue_free()
