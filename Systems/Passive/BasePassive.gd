## Abstract base for all passives (and traits).
## Subclass this, declare hook IDs in get_hook_ids(), implement handle_hook().
## Assign icon in the .tres to show a visual when the passive fires.
class_name BasePassive
extends Resource

@export var passive_name: String = "Passive"
@export var icon: Texture2D = null
@export var is_trait: bool = false

## Return the hook IDs this passive handles.
## Unit builds a lookup table from these on _ready().
func get_hook_ids() -> Array[StringName]:
	return []

## Called by Unit.fire_hook() when a matching hook fires.
## Cast ctx to the expected typed subclass for this hook ID.
func handle_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	pass
