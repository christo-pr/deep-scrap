class_name ItemSpawnEntry
extends Resource

@export var item: ItemData
@export var min_count := 1
@export var max_count := 1
# Depth is normalized: 0.0 = surface, 1.0 = bottom
# To make a rare item, give it a high min_depth, 
# a low bottom_weight, and a higher sell_value.
@export_range(0.0, 1.0) var min_depth := 0.0
@export_range(0.0, 1.0) var max_depth := 1.0
@export var surface_weight := 10.0
@export var bottom_weight := 10.0

func weight_at(depth: float) -> float:
	if depth < min_depth or depth > max_depth:
		return 0.0
	return lerpf(surface_weight, bottom_weight, depth)
