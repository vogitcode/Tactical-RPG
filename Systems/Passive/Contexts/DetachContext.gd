## Context for the &"on_passive_detached" hook.
## Fired inside Unit.remove_passive() BEFORE the passive is removed from the registry.
## The passive receiving this call is the one being removed.
class_name DetachContext
extends PassiveContext

var unit: Unit = null
