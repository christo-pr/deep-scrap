class_name EnemyVisuals
extends Node2D

@export var enemy: Enemy
@export var art_faces_left := false
@export var bob_amplitude := 4.0
@export var bob_speed := 3.0

@onready var sprite: AnimatedSprite2D = $Sprite

var _time := 0.0
var _oneshot_playing := false

func _ready() -> void:
	_time = randf() * TAU
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	enemy.bit.connect(_on_bit)

func _process(delta: float) -> void:
	_time += delta
	sprite.flip_h = enemy.net_facing_left != art_faces_left
	sprite.position.y = sin(_time * bob_speed) * bob_amplitude
	if enemy.net_state == Enemy.State.DEAD:
		_play(&"death")
		return
	if _oneshot_playing:
		return
	_play(&"chase" if enemy.net_state == Enemy.State.CHASE else &"swim")

func _play(anim: StringName) -> void:
	if not sprite.sprite_frames.has_animation(anim):
		anim = &"swim"
	if sprite.animation != anim:
		sprite.play(anim)

func _on_bit() -> void:
	if not sprite.sprite_frames.has_animation(&"bite"):
		return
	_oneshot_playing = true
	sprite.play(&"bite")

func _on_sprite_animation_finished() -> void:
	_oneshot_playing = false
