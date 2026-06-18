## Context for the &"on_before_deal_damage" hook.
## Fired inside DamageEffect.execute_async() before target.take_damage() is called.
## Passives on the ATTACKER (source_unit) may modify damage upward or downward.
class_name DealDamageContext
extends PassiveContext

var source_unit: Unit
var target_unit: Unit
var damage: int = 0
