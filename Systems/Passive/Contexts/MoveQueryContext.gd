## Context for the &"get_move_points" polling hook.
## Passives accumulate bonus into bonus_move_points.
## Unit.get_effective_move_points() reads the total after fire_hook() returns.
class_name MoveQueryContext
extends PassiveContext

var bonus_move_points: int = 0
