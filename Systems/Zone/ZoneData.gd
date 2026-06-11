## Runtime zone — a temporary area effect placed on a specific cell.
## Coexists with BaseTile on the same cell. Managed by ZoneProcessor.
class_name ZoneData
extends Resource

@export var zone_id: StringName = &""
@export var element: StringName = &""
@export var priority: int = 5
## Valid trigger IDs: "unit_entered", "unit_stepped", "on_turn_start"
@export var triggers: Array[StringName] = []
## Applied to the unit when triggered. Receives ActionContext with target_unit = affected unit.
@export var default_effect: BaseEffect = null
## Turns remaining. -1 = permanent. Ticked once per complete turn cycle by ZoneProcessor.
@export var duration_turns: int = -1
@export var can_compound: bool = false
