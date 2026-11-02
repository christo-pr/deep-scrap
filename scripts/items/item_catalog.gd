class_name ItemCatalog
extends RefCounted

const BY_ID: Dictionary[StringName, ItemData] = {
	&"kelp_scrap": preload("res://resources/items/kelp_scrap.tres"),
	&"air_bledder": preload("res://resources/items/air_bladder.tres"),
	&"net_trap": preload("res://resources/items/net_trap.tres"),
}

static func from_id(item_id: StringName) -> ItemData:
	return BY_ID.get(item_id)
