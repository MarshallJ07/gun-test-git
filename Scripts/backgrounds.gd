extends Node3D

@export var station: Node3D
@export var b1: Node3D
@export var b2: Node3D
@export var b3: Node3D
@export var b4: Node3D





var backgrounds = [
	b1,b2,b3,b4
]

var startPos = [
	-300,-800,-1300,-1800
]
var stopTrain := false
var phase := 1

func _ready() -> void:
	EventBus.trainStation.connect(_stop)

func _physics_process(delta):
	b1.body.global_position.z += EventBus.speed * delta
	b1.mesh.global_position.z += EventBus.speed * delta
	EventBus.distance += EventBus.speed * delta / 3600
	if phase == 1:
		b2.body.global_position.z = b1.body.global_position.z - 500
		b3.body.global_position.z = b1.body.global_position.z - 1000
		b4.body.global_position.z = b1.body.global_position.z - 1500
		
		b2.mesh.global_position.z = b1.mesh.global_position.z - 500
		b3.mesh.global_position.z = b1.mesh.global_position.z - 1000
		b4.mesh.global_position.z = b1.mesh.global_position.z - 1500
	elif phase == 2:
		b2.body.global_position.z = b1.body.global_position.z + 1500
		b3.body.global_position.z = b1.body.global_position.z + 1000
		b4.body.global_position.z = b1.body.global_position.z + 500
		
		b2.mesh.global_position.z = b1.mesh.global_position.z + 1500
		b3.mesh.global_position.z = b1.mesh.global_position.z + 1000
		b4.mesh.global_position.z = b1.mesh.global_position.z + 500
	elif phase == 3:
		b2.body.global_position.z = b1.body.global_position.z - 500
		b3.body.global_position.z = b1.body.global_position.z + 1000
		b4.body.global_position.z = b1.body.global_position.z + 500
		
		b2.mesh.global_position.z = b1.mesh.global_position.z - 500
		b3.mesh.global_position.z = b1.mesh.global_position.z + 1000
		b4.mesh.global_position.z = b1.mesh.global_position.z + 500
	elif phase == 4:
		b2.body.global_position.z = b1.body.global_position.z - 500
		b3.body.global_position.z = b1.body.global_position.z - 1000
		b4.body.global_position.z = b1.body.global_position.z + 500
		
		b2.mesh.global_position.z = b1.mesh.global_position.z - 500
		b3.mesh.global_position.z = b1.mesh.global_position.z - 1000
		b4.mesh.global_position.z = b1.mesh.global_position.z + 500
	
	for i in get_children():
		
		if i.name == "stationRoot":
			 
			station.body.global_position.z = i.body.global_position.z
			station.mesh.global_position.z = i.mesh.global_position.z
	if b1.body.global_position.z > 200:
		if stopTrain:
			if b2.name == "stationRoot":
				EventBus.speed = 0
				EventBus.distance = 0
				EventBus.atStation = true
				stopTrain = false
				EventBus.approachingStation = false
				EventBus.nextStation = EventBus.initStationDistance
		if b1.name == "stationRoot":
			b1.name = "background"
			b1.show()
			station.hide()
		b1.body.global_position.z = -1800
		b1.mesh.global_position.z = -1800
		phase = 2
		
	if b2.body.global_position.z > 200:
		if stopTrain:
			if b3.name == "stationRoot":
				EventBus.speed = 0
				EventBus.distance = 0
				EventBus.atStation = true
				stopTrain = false
				EventBus.approachingStation = false
				EventBus.nextStation = EventBus.initStationDistance
		if b2.name == "stationRoot":
			b2.name = "background2"
			b2.show()
			station.hide()
			
		b2.body.global_position.z = -1800
		b2.mesh.global_position.z = -1800
		phase = 3
		
	if b3.body.global_position.z > 200:
		if stopTrain:
			if b4.name == "stationRoot":
				EventBus.speed = 0
				EventBus.distance = 0
				EventBus.atStation = true
				stopTrain = false
				EventBus.approachingStation = false
				EventBus.nextStation = EventBus.initStationDistance
		if b3.name == "stationRoot":
			b3.name = "background3"
			b3.show()
			station.hide()
		b3.body.global_position.z = -1800
		b3.mesh.global_position.z = -1800
		phase = 4
		
	if b4.body.global_position.z > 200:
		if stopTrain:
			if b1.name == "stationRoot":
				EventBus.speed = 0
				EventBus.distance = 0
				EventBus.atStation = true
				EventBus.approachingStation = false
				stopTrain = false
				EventBus.nextStation = EventBus.initStationDistance
		if b4.name == "stationRoot":
			b4.name = "background4"
			b4.show()
			station.hide()
		b4.body.global_position.z = -1800
		b4.mesh.global_position.z = -1800
		phase = 1
	
	
		
	
func _stop() -> void:
	stopTrain = true
	print('STOP')
	station.show()
	if phase == 2:
		b1.name = "stationRoot"
		station.global_position = b1.global_position
		station.global_rotation = b1.global_rotation
		b1.hide()
	elif phase == 3:
		b2.name = "stationRoot"
		station.global_position = b2.global_position
		station.global_rotation = b2.global_rotation
		b2.hide()
	elif phase == 4:
		b3.name = "stationRoot"
		station.global_position = b3.global_position
		station.global_rotation = b3.global_rotation
		b3.hide()
	elif phase == 1:
		b4.name = "stationRoot"
		station.global_position = b4.global_position
		station.global_rotation = b4.global_rotation
		b4.hide()
