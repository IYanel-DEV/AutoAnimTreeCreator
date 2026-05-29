extends Node

@export var player_scene: PackedScene
@export var spawn_point: Node3D

func _ready():
	if not player_scene:
		push_error("Player scene not assigned")
		return
	if not spawn_point:
		push_error("Spawn point not assigned")
		return

	var player = player_scene.instantiate()
	player.position = spawn_point.position
	add_child(player)
