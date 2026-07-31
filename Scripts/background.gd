extends Node3D


@export var distance := 5.0

@onready var body: AnimatableBody3D = $AnimatableBody3D
@onready var mesh: Node3D = $"Sketchfab_model/double track_obj_cleaner_materialmerger_gles"
@onready var background: Node3D = $"."
@export var leader: Node3D

var start_pos
var start_pos1

func _ready():
	start_pos = body.global_position
	start_pos1 = mesh.global_position
