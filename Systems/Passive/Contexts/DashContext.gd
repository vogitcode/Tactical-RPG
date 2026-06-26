## Context for the ON_DASH_EXECUTED hook.
## Fired inside DashMoveCommand after the unit physically dashes to its destination.
class_name DashContext
extends PassiveContext

var unit: Unit = null
var target_unit: Unit = null
