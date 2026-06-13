class_name PropInteractionResult
extends RefCounted

var interrupts: bool = false

static func none() -> PropInteractionResult:
	return PropInteractionResult.new()

static func interrupt() -> PropInteractionResult:
	var r := PropInteractionResult.new()
	r.interrupts = true
	return r
