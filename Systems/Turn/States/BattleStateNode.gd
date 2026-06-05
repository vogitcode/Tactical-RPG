## Base class for all battle state nodes.
## Subclasses override _activate() to emit their typed signal with the token,
## and _transition() to chain to the next state via _turn_system.go_to_*().
class_name BattleStateNode
extends Node

@export var timeout_sec: float = 8.0

var _turn_system: TurnSystem = null

func _ready() -> void:
	_turn_system = get_parent() as TurnSystem

func enter(context: Dictionary = {}) -> void:
	var token := _activate(context)
	if token.pending_count > 0:
		_setup_watchdog(token)
		await token.all_done
	await _transition(context)

func _activate(_context: Dictionary) -> StateCompletionToken:
	return StateCompletionToken.new()

func _transition(_context: Dictionary) -> void:
	pass

func _setup_watchdog(token: StateCompletionToken) -> void:
	if timeout_sec <= 0.0:
		return
	get_tree().create_timer(timeout_sec, false).timeout.connect(
		_on_watchdog_timeout.bind(token), CONNECT_ONE_SHOT
	)

func _on_watchdog_timeout(token: StateCompletionToken) -> void:
	if token.pending_count > 0:
		push_error("[%s] timed out with %d pending subscriber(s)" % [name, token.pending_count])
		token.force_complete()
