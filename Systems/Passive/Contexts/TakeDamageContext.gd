## Context for the &"on_take_damage" hook.
## Fired inside Unit.take_damage() after guard reduction, before HP deduction.
## Passives may reduce modified_damage further (minimum 0).
class_name TakeDamageContext
extends PassiveContext

var original_amount: int = 0
var modified_damage: int = 0
var unit: Unit
