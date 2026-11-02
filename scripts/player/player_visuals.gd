class_name PlayerVisuals
extends Node2D

signal attack_finished

const AXIS_BIAS := 1.2

enum Facing { RIGHT, LEFT, UP, DOWN }

@export var player: Player

@onready var sprite: AnimatedSprite2D = $Sprite

var facing := Facing.RIGHT
var _oneshot_playing := false
var _low_air := false

func _ready() -> void:
	sprite.play(&"idle_side")
	sprite.animation_finished.connect(_on_sprite_animation_finished)

func _physics_process(_delta: float) -> void:
	facing = player.net_facing as Facing
	if player.net_dead:
		_play_death()
		return
	_low_air = player.net_low_air
	sprite.speed_scale = 1.2 if player.net_air_critical else 0.8
	
	_play_locomotion(player.net_moving)

func play_attack() -> bool:
	if _is_locked():
		return false
	var anim := attack_anim()
	_apply_sprite(anim, facing == Facing.LEFT, false)
	_oneshot_playing = true
	return true

func play_attack_forced(anim: StringName, flip: bool) -> bool:
	if _is_locked():
		return false
	_apply_sprite(anim, flip, false)
	_oneshot_playing = true
	return true

func hurt() -> void:
	if _is_locked():
		return
	var anim := &"hurt_up" if facing == Facing.UP else &"hurt_side"
	_apply_sprite(anim, facing == Facing.LEFT, false)
	_oneshot_playing = true

func update_facing(direction: Vector2) -> void:
	var horizontal := absf(direction.x)
	var vertical := absf(direction.y)
	var using_side := facing == Facing.LEFT or facing == Facing.RIGHT
	if using_side:
		if vertical > horizontal * AXIS_BIAS:
			facing = Facing.UP if direction.y < 0.0 else Facing.DOWN
		elif horizontal > 0.0:
			facing = Facing.LEFT if direction.x < 0.0 else Facing.RIGHT
	else:
		if horizontal > vertical * AXIS_BIAS:
			facing = Facing.LEFT if direction.x < 0.0 else Facing.RIGHT
		elif vertical > 0.0:
			facing = Facing.UP if direction.y < 0.0 else Facing.DOWN

func attack_anim() -> StringName:
	var moving := player.velocity.length() > 1.0
	if not moving or facing == Facing.DOWN:
		return &"attack_idle"
	if facing == Facing.UP:
		return &"attack_up"
	return &"attack_side"

func _play_locomotion(moving: bool) -> void:
	if _is_locked():
		return
	var anim := _locomotion_anim(moving)
	var flip := facing == Facing.LEFT
	_apply_sprite(anim, flip, moving)

func _locomotion_anim(moving: bool) -> StringName:
	if _low_air:
		if moving and facing == Facing.UP:
			return &"hurt_up"
		if moving and (facing == Facing.LEFT or facing == Facing.RIGHT):
			return &"hurt_side"
		return &"hurt_idle"
	if moving:
		if facing == Facing.UP:
			return &"swim_up"
		if facing == Facing.DOWN:
			return &"idle_down"
		return &"swim_side"
	return &"idle_side"

func _is_locked() -> bool:
	return _oneshot_playing

func _apply_sprite(anim: StringName, flip: bool, preserve_frame: bool) -> void:
	if sprite.animation == anim and sprite.flip_h == flip:
		return
	var frame := sprite.frame
	var progress := sprite.frame_progress
	sprite.flip_h = flip
	if sprite.animation != anim:
		sprite.play(anim)
		if preserve_frame:
			var count := sprite.sprite_frames.get_frame_count(anim)
			sprite.set_frame_and_progress(mini(frame, count - 1), progress)

func _play_death() -> void:
	_oneshot_playing = false
	sprite.speed_scale = 1.0
	_apply_sprite(&"death", facing == Facing.LEFT, false)

func _on_sprite_animation_finished() -> void:
	if not _oneshot_playing or player.net_dead:
		return
	var was_attack := sprite.animation.begins_with("attack")
	_oneshot_playing = false
	_play_locomotion(player.net_moving)
	if was_attack:
		attack_finished.emit()
