extends CharacterBody3D

@onready var animation_player = $AuxScene/AnimationPlayer
@onready var model = $AuxScene

func _ready():
	# Initialize your player here
	pass

func _physics_process(delta):
	# Handle movement and animation logic
	handle_movement(delta)
	handle_animations()

func handle_movement(delta):
	# Your movement code here
	pass

func handle_animations():
	# Control animations based on player state
	if velocity.length() > 0:
		animation_player.play("walk")
	else:
		animation_player.play("idle")
