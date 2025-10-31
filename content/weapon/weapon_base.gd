class_name WeaponBase extends Node2D

const LEVEL_MULTIPLIER: float = 1.3

var texture_menu: Texture2D
var texture_game: Texture2D
var weapon_name: String
var weapon_slot: int = 0

var level: int = 1
var level_progress: int = 0
var level_required: int = 20



var damage: int = 5

var cooldown_time: float = 0.5
var cooldown: Tween



func _ready() -> void:
	pass

func add_progress(amount: int) -> void:
	level_progress += amount

	if level_progress >= level_required:
		level_up()


func level_up() -> void:
	level += 1
	level_required = int(level_required * LEVEL_MULTIPLIER)
	level_progress = 0

	damage += 2


func attack(_ctx: Dictionary = {}) -> void:
	pass
