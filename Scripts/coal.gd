extends RigidBody3D


var beingHeld = false

@rpc("any_peer","call_local","reliable")
func change_ownership(state:bool) -> void:
	beingHeld = state
