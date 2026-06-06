## Context for the &"on_combat_resolved" hook.
## Fired by PassiveScanner on both attacker and defender after each BattleProcess.
## firing_unit identifies which unit's fire_hook() is currently running.
class_name CombatResolvedContext
extends PassiveContext

var attacker: Unit
var defender: Unit
var action: CombatAction
var condition_result: ConditionResult
var firing_unit: Unit
