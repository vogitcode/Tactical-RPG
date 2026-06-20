## Central registry of all passive hook IDs.
## Use HookId.CONSTANT instead of &"raw_string" to get typo detection at parse time.
##
## Lifecycle hooks (on_*): event-driven, fired when something happens.
## Query hooks (get_*): synchronous, fired to read/modify a computed value via context.
class_name HookId

# --- Lifecycle ---
const ON_PASSIVE_ATTACHED   := &"on_passive_attached"
const ON_PASSIVE_DETACHED   := &"on_passive_detached"
const ON_TAKE_DAMAGE        := &"on_take_damage"
const ON_DEATH_CHECK        := &"on_death_check"
const ON_BEFORE_DEAL_DAMAGE := &"on_before_deal_damage"
const ON_UNIT_TURN_START    := &"on_unit_turn_start"
const ON_UNIT_TURN_END      := &"on_unit_turn_end"
const ON_COMBAT_RESOLVED    := &"on_combat_resolved"
const ON_DASH_EXECUTED      := &"on_dash_executed"

# --- Query ---
const GET_MOVE_POINTS       := &"get_move_points"
const GET_ATTACK_RANGE      := &"get_attack_range"
const GET_RP_BONUS          := &"get_rp_bonus"
const GET_AVAILABLE_ACTIONS := &"get_available_actions"
