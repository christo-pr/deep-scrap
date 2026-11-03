class_name ItemData
extends Resource

enum UseKind { NONE, CONSUME, PLACE }

@export var id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D
@export var max_stack: int = 1
@export var use_kind: UseKind = UseKind.NONE
@export var grant_stat: StringName = &""
@export var grant_amount: float = 0.0
@export var place_scene: PackedScene
@export var sell_value: int = 0
