## Listens to events emitted during action execution and evaluates reaction conditions.
## Writes interrupt flags to InterruptManager or queues parallel reactions.
## Does NOT self-execute actions — it requests; ActionExecutor decides.
class_name ReactionSystem
extends Node

signal parallel_reaction_requested(reactor: Unit, reaction_action: BaseAction, context: Dictionary)

var _interrupt_manager: InterruptManager
var _grid_system: GridSystem
var _action_system: ActionSystem

var _rules: Array[ReactionRule] = []

func setup(im: InterruptManager, grid: GridSystem, action_sys: ActionSystem) -> void:
	_interrupt_manager = im
	_grid_system = grid
	_action_system = action_sys

# --- Rule registration ---

## Add a trap-style interrupt rule.
## condition: func(unit: Unit, cell: Vector2i) -> bool
func register_interrupt_rule(condition: Callable, reason: String) -> void:
	var rule := ReactionRule.new()
	rule.type = ReactionRule.Type.INTERRUPT
	rule.condition = condition
	rule.reason = reason
	_rules.append(rule)

## Add a parallel-reaction rule (e.g., boss counter-attack).
## condition: func(unit: Unit, cell: Vector2i) -> bool
## reactor: func() -> Unit
## reaction: func() -> BaseAction
func register_parallel_rule(condition: Callable, reactor: Callable, reaction: Callable) -> void:
	var rule := ReactionRule.new()
	rule.type = ReactionRule.Type.PARALLEL
	rule.condition = condition
	rule.reactor_getter = reactor
	rule.reaction_getter = reaction
	_rules.append(rule)

# --- Called by ActionExecutor / MoveAction at each step checkpoint ---

func evaluate_step(unit: Unit, cell: Vector2i) -> void:
	for rule in _rules:
		if not rule.condition.call(unit, cell):
			continue
		match rule.type:
			ReactionRule.Type.INTERRUPT:
				_interrupt_manager.flag_interrupt(unit, rule.reason)
			ReactionRule.Type.PARALLEL:
				var reactor: Unit = rule.reactor_getter.call()
				var reaction: BaseAction = rule.reaction_getter.call()
				parallel_reaction_requested.emit(reactor, reaction, {"target_unit": unit, "target_cell": cell})

func clear_rules() -> void:
	_rules.clear()

# --- Inner class ---

class ReactionRule:
	enum Type { INTERRUPT, PARALLEL }
	var type: Type
	var condition: Callable
	var reason: String = ""
	var reactor_getter: Callable
	var reaction_getter: Callable
