class_name EnemyData
extends Resource

@export_group("Stats")
@export var health_max := 30.0
@export var bite_damage := 15.0

@export_group("Movement")
@export var wander_speed := 60.0
@export var chase_speed := 200.0
@export var flee_speed := 150.0
@export var acceleration := 300.0
@export var wander_radius := 300.0
@export_range(0.0, 1.0) var vertical_bias := 0.4
@export var wander_retarget_time := 4.0

@export_group("Behavior")
@export var aggressive := true
@export var detect_radius := 250.0
@export var lose_radius := 450.0
@export var bite_range := 50.0
@export var chase_duration := 3.0
@export var flee_duration := 2.0
@export var aggro_cooldown := 3.0
