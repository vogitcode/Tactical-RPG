## Context for the &"on_death_check" hook.
## Fired inside Unit.take_damage() when HP reaches 0, before _on_death().
## If any passive sets prevent_death = true the unit survives at 1 HP.
class_name DeathCheckContext
extends PassiveContext

var prevent_death: bool = false
var unit: Unit
