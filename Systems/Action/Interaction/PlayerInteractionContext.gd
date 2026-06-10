## Mutable context shared across all player interaction states.
## SM owns this object; states read and write active_unit and pending_action.
class_name PlayerInteractionContext
extends RefCounted

var active_unit: Unit = null
var pending_action: BaseAction = null
var action_system: ActionSystem = null
var grid_system: GridSystem = null
