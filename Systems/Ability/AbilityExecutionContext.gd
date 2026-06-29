## Carries all service references an ability needs during execution.
## Assembled once by AbilitySystem and passed to BaseAbility.execute().
## Each ability reads only the fields it needs — unused fields are ignored.
class_name AbilityExecutionContext
extends RefCounted

var source_unit: Unit
var grid_system: GridSystem
var unit_manager: UnitManager
var turn_system: TurnSystem
var prop_system: PropSystem
var unit_spawner: UnitSpawner
