## Base marker class for all passive hook contexts.
## PassiveContext itself carries no data — use typed subclasses per hook ID.
## The uniform type is required so Unit.fire_hook() has a fixed signature.
class_name PassiveContext
extends RefCounted
