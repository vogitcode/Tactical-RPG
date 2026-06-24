## Context objects injected by TileProcessor into tile hooks (R3).
## Tiles receive context, return Array[TileRequest] — never pull world state.
class_name TileContexts


## Passed to BaseTile.on_unit_enter().
class TileEnterContext extends RefCounted:
	var unit: Node               # entering unit
	var pos: Vector2i            # tile position
	var neighbors: Array[TileNeighborInfo] = []


## Passed to BaseTile.on_turn_start().
class TileTurnContext extends RefCounted:
	var unit: Node               # unit whose turn started
	var pos: Vector2i


## Passed to BaseTile.on_round_start() — for spread, decay, and per-round effects.
class TileRoundContext extends RefCounted:
	var pos: Vector2i
	var neighbors: Array[TileNeighborInfo] = []


## Passed to BaseTile.on_external_effect() — e.g. fire zone ignites GrassTile.
class TileEffectContext extends RefCounted:
	var pos: Vector2i
	var effect_type: StringName
	var source: Node = null      # zone, prop, or unit that triggered the effect
