extends Node

signal needRepairs
signal repairing(object, dmg:float)
signal statChange
signal trainStation
var backgroundScroll = []

@export var maxFuel := 1000.0
@export var maxSpeed := 200.0
@export var acceleration: float = 15.0

var atStation := false
var approachingStation := false

var targetSpeed := 50.0
var repairNode: String
var initStationDistance := 1.0

var speed: float = 50.0
var fuel: float = 150.0
var nextStation := initStationDistance
var distance = 0
var stats = {
		"speed": "",
		"fuel": "",
		"next station": "",
		"distance": "",
	}
	
func _physics_process(delta: float) -> void:
	if !multiplayer.is_server():
		return
	if !atStation:
		
		fuel = max(0.0, fuel - ((speed / 50.0) + 0.01) * delta)
		
		if fuel <= 0.0:
			targetSpeed = 0.0
				
		if speed != targetSpeed:
			speed = move_toward(speed, targetSpeed, acceleration * delta)
		
		nextStation = initStationDistance - distance
		if nextStation < 0.4 and !approachingStation:
			trainStation.emit()
			approachingStation = true
	
	statChange.emit()
