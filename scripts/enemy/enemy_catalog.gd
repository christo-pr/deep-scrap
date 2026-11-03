class_name EnemyCatalog
extends RefCounted

const BY_ID: Dictionary[StringName, PackedScene] = {
	&"shark": preload("res://scenes/enemies/shark.tscn"),
	&"fish": preload("res://scenes/enemies/fish.tscn"),
}

static func scene_for(enemy_id: StringName) -> PackedScene:
	return BY_ID.get(enemy_id)
