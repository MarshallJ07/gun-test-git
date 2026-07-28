extends StaticBody3D

@onready var particles: GPUParticles3D = $particles
@onready var healthBar: ProgressBar = $SubViewport/ProgressBar

var targetParticleAmount:int

var health := 100
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.needRepairs.connect(_need_repairs)
	EventBus.repairing.connect(_repairing)
	
func _need_repairs() -> void:
	if EventBus.repairNode == str(name):
		particles.emitting = true
		
		healthBar.value = 50
		particles.amount_ratio = 100/healthBar.value - 1


func _repairing(object, dmg:float) -> void:
	if object != self:
		return
	_repair_host.rpc(dmg)

@rpc("any_peer","call_local","reliable")
func _repair_host(dmg:int) -> void:
	if healthBar.value < 100:
		healthBar.value += dmg
	else:
		healthBar.value = 100
	particles.amount_ratio = 100/healthBar.value - 1
	
	
