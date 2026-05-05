extends CharacterBody2D

class_name Player

@export var speed: float = 300.0
@export var health: int = 10
@export var has_shield: bool = false
@export var has_double_attack: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		self.velocity = direction * self.speed
		if self.animated_sprite:
			var frames: SpriteFrames = self.animated_sprite.sprite_frames
			if frames and frames.has_animation("walking"):
				self.animated_sprite.play("walking")
			self.animated_sprite.flip_h = direction.x < 0
	else:
		self.velocity = Vector2.ZERO
		if self.animated_sprite:
			var frames: SpriteFrames = self.animated_sprite.sprite_frames
			if frames and frames.has_animation("idle"):
				self.animated_sprite.play("idle")
			
	self.move_and_slide()
