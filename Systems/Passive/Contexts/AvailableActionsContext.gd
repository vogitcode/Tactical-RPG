## Context for the &"get_available_actions" hook.
## Passives append extra actions to extra_actions — Unit.get_available_actions()
## merges them with the data-driven action list from UnitData.
class_name AvailableActionsContext
extends PassiveContext

var unit: Unit = null
var extra_actions: Array[BaseAction] = []
