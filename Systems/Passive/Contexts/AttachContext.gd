## Context for the &"on_passive_attached" hook.
## Fired inside Unit.add_passive() after the hook index is rebuilt.
## The passive receiving this call is the one being attached.
class_name AttachContext
extends PassiveContext

var unit: Unit = null
