extends CharacterBody2D


@export var speed: float = 300.0
@export var health: int = 10
@export var has_shield: bool = false
@export var has_double_attack: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Removed movement logic as per request. Use mouse to click doors.
func _physics_process(_delta: float) -> void:
	pass
