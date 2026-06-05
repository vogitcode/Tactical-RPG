## Combat resolution orchestrator — replaces BattleProcessor.
##
## Accepts CombatAction submissions, queues them, and drains sequentially.
## Child nodes hold each processing step:
##   ReactionCollector → Arbitrator → EffectExecutor
##   PassiveScanner (Phase 5 — not yet implemented)
##
## Queue management (_queue, _drain, _is_running, sequence_done) is internal.
class_name CombatSystem
extends Node

signal sequence_done

@onready var _reaction_collector: ReactionCollector = $ReactionCollector
@onready var _arbitrator: Arbitrator                 = $Arbitrator
@onready var _effect_executor: EffectExecutor        = $EffectExecutor

var _grid_system: GridSystem = null
var _queue: Array[BattleProcess] = []
var _is_running: bool = false
var _last_result: ActionResult = null

func setup(grid: GridSystem) -> void:
	_grid_system = grid

## Handler interface — called by ActionSystem dispatch for category &"combat".
func handle_action(action: BaseAction, source_unit: Unit) -> ActionResult:
	var combat_action := action as CombatAction
	_queue.append(_make_process(combat_action, source_unit))
	if not _is_running:
		await _drain()
	else:
		await sequence_done
	return _last_result

func _make_process(action: CombatAction, source_unit: Unit) -> BattleProcess:
	var p := BattleProcess.new()
	p.action = action
	p.source_unit = source_unit
	p.reactor_unit = action.target_unit
	p.reaction = _reaction_collector.collect(action, action.target_unit)
	return p

func _drain() -> void:
	_is_running = true
	while not _queue.is_empty():
		var process: BattleProcess = _queue.pop_front()
		_last_result = await _run_process(process)
		# Phase 5: PassiveScanner will scan _last_result → enqueue triggered processes here
	_is_running = false
	sequence_done.emit()

func _run_process(process: BattleProcess) -> ActionResult:
	var condition := _arbitrator.resolve(process.action, process.source_unit, process.reaction, process.reactor_unit)
	if not condition.initiator_hit():
		await process.reaction.execute_async(process.reactor_unit)
	return await _effect_executor.execute(process.action, process.source_unit, condition, _grid_system)
