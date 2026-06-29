class_name PropInteractionResult
extends RefCounted

var interrupts: bool = false
## Optional command executed by PropSystem in Phase 2 (after interrupt flag is set).
var command: BaseCommand = null

static func none() -> PropInteractionResult:
	return PropInteractionResult.new()

static func interrupt() -> PropInteractionResult:
	var r := PropInteractionResult.new()
	r.interrupts = true
	return r

static func interrupt_with(cmd: BaseCommand) -> PropInteractionResult:
	var r := PropInteractionResult.new()
	r.interrupts = true
	r.command = cmd
	return r
