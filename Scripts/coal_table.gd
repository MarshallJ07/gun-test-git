extends Area3D


func _physics_process(delta: float) -> void:
	for i in get_overlapping_bodies():
		if i.is_in_group("coal"):
			i.queue_free()
