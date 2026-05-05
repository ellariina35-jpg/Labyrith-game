extends Node2D

@onready var player: Player = $Player
@onready var message_label: Label = $CanvasLayer/HUD/MessageLabel
@onready var doors: Array = [$Path1, $Path2, $Path3]
@onready var start_panel: Panel = $CanvasLayer/HUD/StartPanel
@onready var game_over_panel: Panel = $CanvasLayer/HUD/GameOverPanel

@onready var health_label: Label = $CanvasLayer/HUD/HealthLabel
@onready var combat_panel: Panel = $CanvasLayer/HUD/CombatPanel
@onready var battle_label: Label = $CanvasLayer/HUD/CombatPanel/BattleLabel
@onready var monster_label: Label = $CanvasLayer/HUD/CombatPanel/MonsterLabel
@onready var roll_label: Label = $CanvasLayer/HUD/CombatPanel/RollLabel
@onready var attack_button: Button = $CanvasLayer/HUD/CombatPanel/AttackButton

var empty_doors_count: int = 0
var is_game_over: bool = false
var game_started: bool = false
var monster_health: int = 0
var is_player_turn: bool = true

func _ready() -> void:
	self.start_panel.visible = true
	self.game_over_panel.visible = false
	self.combat_panel.visible = false
	if self.player:
		self.player.set_physics_process(false)
	
	if not self.attack_button.pressed.is_connected(self._on_attack_button_pressed):
		self.attack_button.pressed.connect(self._on_attack_button_pressed)
	
	var start_button: Button = self.start_panel.get_node("StartButton")
	if not start_button.pressed.is_connected(self._on_start_button_pressed):
		start_button.pressed.connect(self._on_start_button_pressed)
		
	var restart_button: Button = self.game_over_panel.get_node("RestartButton")
	if not restart_button.pressed.is_connected(self._on_restart_button_pressed):
		restart_button.pressed.connect(self._on_restart_button_pressed)
	
	self.update_ui()
	self.message_label.text = "Welcome to the Labyrinth"

func start_new_game() -> void:
	self.empty_doors_count = 0
	self.is_game_over = false
	self.game_started = true
	self.start_panel.visible = false
	self.game_over_panel.visible = false
	self.combat_panel.visible = false
	
	if self.player:
		self.player.set_physics_process(true)
		self.player.health = 10
		self.player.has_shield = false
		self.player.has_double_attack = false
		self.reset_player()
	
	self.randomize_doors()
	self.update_ui()
	self.message_label.text = "Choose a door!"

func _on_start_button_pressed() -> void:
	self.start_new_game()

func _on_restart_button_pressed() -> void:
	self.start_new_game()

func randomize_doors() -> void:
	var types: Array[int] = [0, 1, 2] # 0: Monster, 1: Chest, 2: Empty
	types.shuffle()
	
	for i in range(self.doors.size()):
		self.doors[i].set_type(types[i])
		if not self.doors[i].door_entered.is_connected(self._on_door_entered):
			self.doors[i].door_entered.connect(self._on_door_entered)

func _on_door_entered(type: String) -> void:
	if self.is_game_over or not self.game_started:
		return
		
	match type:
		"monster":
			self.message_label.text = ""
			self.start_combat()
		"chest":
			self.apply_treasure()
			self.reset_player()
		"empty":
			self.empty_doors_count += 1
			self.message_label.text = "An empty door! You are closer to escape."
			self.update_ui()
			if self.empty_doors_count >= 4:
				self.message_label.text = "YOU ESCAPED THE LABYRINTH! YOU WIN!"
				self.trigger_game_over(true)
			else:
				self.reset_player()
	
	if not self.is_game_over and type != "monster":
		self.randomize_doors()

func apply_treasure() -> void:
	var roll: int = randi() % 4
	if self.player:
		match roll:
			0:
				self.player.health += 2
				self.message_label.text = "Found a Health Potion! +2 HP"
			1:
				self.player.health += 5
				self.message_label.text = "Found a Great Health Potion! +5 HP"
			2:
				self.player.has_shield = true
				self.message_label.text = "Found a Shield! Next attack negated."
			3:
				self.player.has_double_attack = true
				self.message_label.text = "Found an Attack Buff! Next attack x2."
	self.update_ui()

func start_combat() -> void:
	if self.player:
		self.player.set_physics_process(false)
	self.monster_health = (randi() % 5) + 5
	self.is_player_turn = true
	self.battle_label.text = "Monster! Let's battle!"
	self.monster_label.text = "Monster Health: " + str(self.monster_health)
	self.roll_label.text = "It is your turn to roll!"
	self.attack_button.text = "Roll the dice? (Yes)"
	self.attack_button.disabled = false
	self.combat_panel.visible = true

func _on_attack_button_pressed() -> void:
	if self.is_player_turn:
		self.player_attack()
	else:
		self.monster_attack()

func player_attack() -> void:
	self.attack_button.disabled = true
	var player_roll: int = (randi() % 6) + 1
	var player_damage: int = player_roll
	
	if self.player and self.player.has_double_attack:
		player_damage *= 2
		self.player.has_double_attack = false
	
	self.monster_health -= player_damage
	self.monster_label.text = "Monster Health: " + str(max(0, self.monster_health))
	self.roll_label.text = "You rolled a " + str(player_roll) + "! Dealt " + str(player_damage) + " damage."
	
	await self.get_tree().create_timer(1.5).timeout
	
	if self.monster_health <= 0:
		self.roll_label.text = "Monster defeated!"
		await self.get_tree().create_timer(1.0).timeout
		self.attack_button.disabled = false
		self.combat_panel.visible = false
		if self.player:
			self.player.set_physics_process(true)
			self.reset_player()
		self.randomize_doors()
		self.update_ui()
		self.message_label.text = "Monster defeated! Choose another door."
	else:
		self.is_player_turn = false
		self.battle_label.text = "Monster's turn to roll..."
		self.attack_button.text = "Continue?"
		self.attack_button.disabled = false

func monster_attack() -> void:
	self.attack_button.disabled = true
	var monster_roll: int = (randi() % 6) + 1
	var monster_damage: int = monster_roll
	
	if self.player:
		if self.player.has_shield:
			monster_damage = 0
			self.player.has_shield = false
			self.roll_label.text = "Monster rolled " + str(monster_roll) + ". SHIELD BLOCKED!"
		else:
			self.player.health -= monster_damage
			self.roll_label.text = "Monster rolled " + str(monster_roll) + ". You took " + str(monster_damage) + " damage!"
	
	self.update_ui()
	await self.get_tree().create_timer(1.5).timeout
	
	if self.player and self.player.health <= 0:
		self.combat_panel.visible = false
		self.trigger_game_over(false)
	else:
		self.is_player_turn = true
		self.battle_label.text = "It is your turn to roll!"
		self.attack_button.text = "Roll the dice? (Yes)"
		self.attack_button.disabled = false

func update_ui() -> void:
	if self.player:
		self.health_label.text = "Health: " + str(self.player.health)
		if self.player.has_shield: self.health_label.text += " [SHIELD]"
		if self.player.has_double_attack: self.health_label.text += " [ATK x2]"

func reset_player() -> void:
	if self.player:
		self.player.velocity = Vector2.ZERO
		self.player.position = Vector2(576, 500)

func trigger_game_over(win: bool) -> void:
	self.is_game_over = true
	self.game_started = false
	if self.player:
		self.player.set_physics_process(false)
	self.game_over_panel.visible = true
	var game_over_label = self.game_over_panel.get_node("GameOverLabel")
	if win:
		game_over_label.text = "YOU ESCAPED!"
	else:
		game_over_label.text = "GAME OVER"
