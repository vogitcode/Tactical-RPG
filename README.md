# Tactical RPG — Core Systems

A modular rebuild of core systems for a turn-based tactical game, inspired by **Into the Breach** and **XCOM**. Built with **Godot Engine 4.6** and developed alongside **Claude Code**.

The goal is not to ship a complete game — it is to build each tactical system correctly: standalone, signal-based, and reusable. Grid, turn management, combat resolution, AI, and passive abilities are each an independent module that communicates through well-defined boundaries.

---

## Architecture

Every system follows the same layered structure:

| Layer | Role |
|-------|------|
| **Core** | Pure data + algorithm. No Godot Node dependency. Could run headless. |
| **Facade** | Single entry point other systems call. Orchestrates Core logic, owns lifecycle, emits signals. |
| **Adapter** | Bridges incompatible boundaries — screen ↔ grid coordinates, UI signal ↔ gameplay callback, resource data ↔ runtime Node. |
| **Visual / Infrastructure** | Godot-specific rendering and platform layer: TileMapLayer, Sprite2D, scene tree nodes. |

**Communication rule:** Systems talk to each other only at the **Facade layer**, via **signals**. Core layers never reference each other directly. A system's Core is invisible to everything outside it.

---

## Systems

### GridSystem

Manages the 2D grid — terrain data, unit placement, movement queries, line-of-sight, and visual rendering.

**Core**
- `GridData` — 2D dictionary mapping `Vector2i → CellData` (tile + occupant). Single source of truth for terrain and unit positions.
- `GridLogic` — Stateless algorithms: BFS reachability, A* pathfinding, Manhattan ring for attack range. Reads `GridData`; no side effects.
- `BaseTile` hierarchy — Resource-based terrain types (`FloorTile`, `WallTile`, `WaterTile`, `GrassTile`, `CorruptionTile`, `VoidTile`). Each tile defines `can_enter()`, `movement_cost`, `blocks_los`, and lifecycle hooks (`on_unit_enter`, `on_turn_start`).

**Facade**
- `GridSystem` — Single entry point. Orchestrates Core queries, manages occupant state (`place_unit`, `move_unit`, `clear_occupant`), controls highlight state, and fires tile lifecycle hooks at the right battle moments.

**Adapter**
- `GridCoordinateAdapter` — Converts between screen-space `Vector2` and grid-space `Vector2i`.
- `TopDownGridAdapter` — Top-down specific coordinate math (cell size, origin offset).

**Visual**
- `GridVisualizer` — Pure renderer. `TileMapLayer` for terrain sprites; `_draw()` for highlight overlays, grid lines, hover state, and path preview. No input handling, no game logic.

---

### TurnSystem

Manages battle turn order — faction sequencing, unit sequencing, deferred units, and the battle state machine lifecycle.

**Core**
- Turn order logic — Faction ordering (ascending team ID), unit sequencing within a faction, `_deferred_units` (units that used WaitAction go to the end of the faction turn), `_completed_units` (prevents re-activation of already-finished units in the same faction turn).
- `BattleState` enum — 10 states from `IDLE` through `BATTLE_END`.

**Facade**
- `TurnSystem` — Context holder (current unit, current faction, turn number) + signal emitter + navigation service. Exposes `go_to_X()` semantic transitions and navigation queries (`get_next_unit_in_faction()`, `get_next_deferred_unit_in_faction()`). States call these methods; TurnSystem never sequences them directly.

**Adapter**
- `StateCompletionToken` — RefCounted async handshake. Subscribers `claim()` a token; the state waits until all claims are released before transitioning. Decouples "when is this state done" from "what the state does."
- `BattleStateNode` — Base class for scene-tree state nodes. Defines the `enter() → _activate() → await token → _transition()` lifecycle. Each subclass overrides `_transition()` to decide the next state and call the appropriate `go_to_X()`.

**Infrastructure**
- 9 concrete state nodes in the scene tree — `BattleStartState`, `TurnStartState`, `FactionTurnStartState`, `UnitTurnStartState`, `UnitActingState`, `UnitTurnEndState`, `FactionTurnEndState`, `TurnEndState`, `BattleEndState`. Each owns its own sequencing logic; none knows about the others.

---

### ActionSystem

Dispatches player or AI action choices to the correct handler. Manages the action lifecycle: selection → target resolution → execution → post-action routing.

**Core**
- `BaseAction` (Resource) — Action data: `action_id`, `category` (StringName), `TargetMode` enum (`SELF / TILE / UNIT`), virtual `is_target_resolved()`, `base_rp`, `can_execute()`. Pure data — no execution logic at this layer.
- `ActionResult` — Execution outcome: `COMPLETED`, `INTERRUPTED`, `DEFERRED`, `CANCELLED`, `FAILED`.
- `ActionContext` — 5-field data bag passed into the effect pipeline: `unit`, `target_cell`, `target_unit`, `grid_system`, `condition_result`.

**Facade**
- `ActionSystem` — State machine (`IDLE → AWAITING_TARGET → EXECUTING`). Holds a handler registry (`StringName → Node`). Routes `on_action_chosen()` → `_dispatch(action, unit)` → `handler.handle_action()`. Does not know how any action executes.

**Adapter**
- `ActionMenu` — UI adapter. Receives `show_menu_requested(unit, pos)` signal from ActionSystem → renders the button list. Emits `action_chosen(action)` back. Knows nothing about gameplay logic.

**Infrastructure**
- Per-category handler nodes — `MoveSystem`, `CombatSystem`, and `TurnSystem` each implement `handle_action(action, unit) → ActionResult`. Registered by category string at startup (`&"move"`, `&"combat"`, `&"turn_control"`).

---

### MoveSystem

Standalone movement execution. Computes reachable cells, finds paths, and animates unit movement cell-by-cell with interrupt support.

**Core**
- Movement validation and per-cell async loop — delegates reachability and pathfinding to `GridSystem`. Checks interrupt flag after each step; returns `ActionResult.INTERRUPTED` if flagged.

**Facade**
- `MoveSystem` — Public API: `get_reachable_cells()`, `find_path()`, `execute_move_async(unit, path, interrupt_manager) → ActionResult`. Any mechanic needing to move a unit calls this; no duplication of movement logic elsewhere.

---

### CombatSystem

Resolves combat — collects reactions, arbitrates outcomes via the RP system, executes the damage effect pipeline, and fires post-combat passive hooks.

**Core**
- `ConditionResult` — Arbitration output: `initiator_wins: bool`, `reactor_wins: bool`. Factories: `full_initiator()`, `full_reactor()`, `both_partial()`.
- `BattleProcess` (queue item) — Carries `action: CombatAction`, `source_unit`, `reaction: BaseReaction`, `reactor_unit` through the resolution pipeline.
- `BaseReaction` (Resource abstract) — `can_trigger(action, reactor) → bool`, `execute_async(reactor)`. Fields: `base_rp`, `defensive_stat`.
- `NullReaction` — No-reaction placeholder. Makes the pipeline uniform — the drain loop never checks for null.

**Facade**
- `CombatSystem` — Queue management + drain loop. Orchestrates the child nodes in sequence: collect → arbitrate → execute. `handle_action()` is the entry point dispatched from ActionSystem.

**Adapter**
- `ReactionCollector` — Queries `reactor.get_reactions()` → finds the first reaction where `can_trigger()` is true → returns it (or `NullReaction`). Decouples reaction selection from resolution.
- `PassiveScanner` — After each `_run_process()`, fires `&"on_combat_resolved"` hook on both units via `unit.fire_hook()`. Lets passives react to combat outcomes without CombatSystem knowing about them.

**Infrastructure**
- `Arbitrator` — Computes RP for each side (base_rp + passive bonus via `&"get_rp_bonus"` hook) → deterministic resolution: higher RP wins; tie → `both_partial()`.
- `EffectExecutor` — Runs the `BaseEffect` pipeline (pre → hit/miss branch → post). Deducts AP, sets `has_acted`. `DamageEffect` delegates to `unit.take_damage()`.
- Concrete reactions — `BlockReaction` (triggers when target has "guarding" status + action is attack), `DodgeReaction` (triggers when target has 0 action points + action is attack).

---

### ReactionSystem

Evaluates movement interrupts — per-step conditions that can stop a unit's movement mid-path.

**Core**
- Rule evaluation — Two rule types: `INTERRUPT` (stop movement, apply consequence) and `PARALLEL` (fire alongside, movement continues). Each rule defines its trigger condition and target cell.

**Facade**
- `ReactionSystem` — Maintains registered interrupt rules. `evaluate_step(unit, cell)` is called after each movement step; if any rule triggers, it flags an interrupt in `InterruptManager`.

---

### PassiveSystem

Hook-driven passive abilities. Units expose a hook interface; systems fire hooks without knowing what passives exist. Passives intercept at specific points to query or modify values.

**Core**
- `BasePassive` (Resource abstract) — `get_hook_ids() → Array[StringName]`, `handle_hook(hook_id, ctx: PassiveContext)`. Each passive declares which hooks it handles.
- `PassiveContext` typed subclasses — One per hook ID. Carry the data the passive may read or modify:
  - `MoveQueryContext` — `bonus_move_points` (writable)
  - `AttackRangeQueryContext` — `bonus_range` (writable)
  - `RPQueryContext` — `stat_name`, `bonus_rp` (writable)
  - `TurnStartContext` — `unit` reference
  - `TakeDamageContext` — `original_amount`, `modified_damage` (writable), `unit`
  - `DeathCheckContext` — `prevent_death` (writable), `unit`
  - `CombatResolvedContext` — `attacker`, `defender`, `action`, `condition_result`, `firing_unit`

**Facade**
- `Unit.fire_hook(hook_id, ctx)` — Iterates `_hook_index[hook_id]`, calls each passive's `handle_hook()`. Systems call this method only — they never see the passive array.
- `Unit.get_effective_move_points()` / `get_effective_attack_range()` — Convenience query methods that fire the relevant hook and return the modified value.

**Adapter**
- `UnitData.passives: Array[BasePassive]` (Resource export) — Passives are data-configured in `.tres` files. Unit reads this on `_ready()` to build `_hook_index`. No hardcoded passive logic in unit scripts.

**Infrastructure**
- Concrete passives — `SwiftMoverPassive` (+3 move), `ArmorPassive` (-2 flat damage), `LastStandPassive` (prevent death once, self-remove), `ThornsPassive` (reflect 2 dmg on hit), `LongReachPassive` (+1 attack range), `AggressivePassive` (+10 RP), `RegenerationPassive` (+2 HP/turn).

---

### AISystem

Routes AI decisions per faction. Builds a context snapshot, dispatches to the correct brain, and submits the chosen action through the same interface as player input.

**Core**
- `FactionAIBrain` (Node abstract) — `@export faction_id: int`, `decide(unit: Unit, ctx: AIContext) → BaseAction`. Each brain fills action data directly (path for move, target for attack) so `is_target_resolved()` returns true — the action executes immediately, skipping the player target-selection state.
- `AIContext` (RefCounted snapshot) — `acting_unit`, `allies: Array[Unit]`, `enemies: Array[Unit]`, `grid_system`. Built fresh per decision; brains do not hold mutable state.

**Facade**
- `AISystem` — On `ai_turn_requested(unit)`: await 0.4s delay → find the child `FactionAIBrain` matching `unit.team` → build `AIContext` → `brain.decide()` → submit via `action_system.on_action_chosen(action)`.

**Infrastructure**
- `BanditBrain` (faction 1) — If an enemy is within attack range, submit `AttackAction` targeting the nearest. Otherwise, submit `MoveAction` with a path toward the nearest enemy.

---

### InputSystem

Single entry point for all player input. Converts Godot input events to semantic signals.

**Facade**
- `InputSystem` — `_unhandled_input()` converts raw events: mouse motion → `tile_hovered(Vector2i)`, left click → `tile_clicked(Vector2i)`, keys 1–5 → `action_hotkey_pressed(StringName)`, Escape / right-click → `cancel_requested()`. GUI nodes take priority — unhandled means no UI element consumed the event.

---

### StatusEffect System

Applies, ticks, and expires time-limited effects on units. Fires hooks at turn boundaries.

**Core**
- `StatusEffect` (Resource base) — `status_id`, `duration`. Virtual hooks: `tick()`, `is_expired()`, `on_turn_start(unit)`, `on_expire(unit)`.

**Facade**
- `StatusEffectReceiver` (Node, child of Unit) — `apply()`, `has_effect()`, `remove_effect()`. Two distinct processing methods with different responsibilities: `process_turn_start(unit)` fires `on_turn_start` hooks only (no tick); `tick_and_expire(unit)` ticks and removes expired effects only (no hooks).
- `Unit.apply_status() / has_status() / remove_status()` — Delegates to the receiver. The system-facing API; callers do not reference `StatusEffectReceiver` directly.

**Adapter**
- `TurnEffectProcessor` — Bridges TurnSystem events to status processing. Subscribes to `UnitTurnStartState.activated` → calls `receiver.process_turn_start()`. Ensures hooks fire at the correct battle phase regardless of whether it is a fresh or deferred unit turn.

---

### GoalSystem

Evaluates win/lose conditions independently of turn flow.

**Core**
- Condition logic — After each unit death: count alive units per team. `win` if only team 0 remains; `lose` if only team 1 remains; `draw` if both are empty.

**Facade**
- `GoalSystem` — Subscribes to `UnitManager.unit_died`. On each death, evaluates conditions and emits `goal_achieved(result: StringName)`. Wired to `TurnSystem.trigger_battle_end()` by the Compositor — GoalSystem does not know TurnSystem exists.

---

### UI Layer

Displays game state. Two separate managers handle screen-space and world-space overlays because they render in different coordinate systems.

**Facade**
- `ScreenUIManager` (CanvasLayer) — Coordinates screen-fixed HUD: `ActionMenu` (action button list), `StatusLabel` (turn and battle state text).
- `WorldUIManager` (Node2D, world-space) — Coordinates world-following overlays: `HealthUIManager` (HP bars positioned via `unit.global_position`).

**Adapter**
- Signal wiring lives entirely in `GameLoop._wire_cross_boundary()` — the only place in the codebase that holds references to both gameplay systems and UI nodes. Neither side references the other directly.

**Visual**
- Control nodes (Button, Label, ProgressBar) populated dynamically from gameplay signals. `HealthUIManager` draws HP bars in world space so they follow units through camera zoom.

---

## Mechanics, Coupling & Dependencies

Each mechanic is broken into steps. Every step is labeled with the system that handles it and the layer at which coupling occurs.

**Coupling types used below:**
- **Signal** — loose coupling; sender does not know receiver exists
- **Handler registry** — ActionSystem routes by category string; does not know the handler's type
- **Hook** — system fires `unit.fire_hook(id, ctx)`; does not know which passives respond
- **Direct call** — Facade-to-Facade or internal child-node call within the same system boundary

---

### 1. Unit Movement

| Step | System | Layer | Coupling |
|------|--------|-------|----------|
| Player presses hotkey 1 | InputSystem | Facade | — |
| `action_hotkey_pressed("move")` | InputSystem → ActionSystem | Facade → Facade | **Signal** |
| ActionSystem activates MoveAction | ActionSystem | Facade | Internal |
| `Unit.get_effective_move_points()` called | ActionSystem → Unit | Facade → Facade | Direct call |
| `&"get_move_points"` hook fires | Unit → PassiveSystem | Facade → Core | **Hook** |
| SwiftMoverPassive writes `+3` to `MoveQueryContext` | PassiveSystem | Core | Reads/writes context |
| `GridSystem.show_move_range(reachable_cells)` | ActionSystem → GridSystem | Facade → Facade | Direct call |
| Player clicks target tile | InputSystem | Facade | — |
| `tile_clicked(Vector2i)` | InputSystem → GridSystem → ActionSystem | Facade chain | **Signal chain** |
| `MoveAction.resolve_target()` fills path | ActionSystem → MoveAction | Facade → Core | Direct call |
| ActionSystem routes to `MoveSystem.handle_action()` | ActionSystem → MoveSystem | Facade → Facade | **Handler registry** |
| `execute_move_async()` — per-cell loop | MoveSystem | Facade | Internal |
| `GridSystem.move_unit()` per step | MoveSystem → GridSystem | Facade → Facade | Direct call |
| `ReactionSystem.evaluate_step()` per step | MoveSystem → ReactionSystem | Facade → Facade | Direct call |
| GridVisualizer updates unit position | GridSystem → GridVisualizer | Facade → Visual | Internal |

> Core coupling: `MoveAction` (Core) carries the `path` data that `MoveSystem` (Facade) consumes. No direct Core-to-Core dependency between systems.

---

### 2. Attack / Combat Resolution

| Step | System | Layer | Coupling |
|------|--------|-------|----------|
| Player presses hotkey 2 | InputSystem | Facade | — |
| `action_hotkey_pressed("attack")` | InputSystem → ActionSystem | Facade → Facade | **Signal** |
| `CombatAction.on_selected()` | ActionSystem → CombatAction | Facade → Core | Direct call |
| `Unit.get_effective_attack_range()` → `&"get_attack_range"` hook | Unit → PassiveSystem | Facade → Core | **Hook** |
| `GridSystem.show_attack_range()` | ActionSystem → GridSystem | Facade → Facade | Direct call |
| Player clicks target | InputSystem → GridSystem → ActionSystem | Facade chain | **Signal chain** |
| `CombatAction.resolve_target()` fills `target_cell` + `target_unit` | ActionSystem → CombatAction | Facade → Core | Direct call |
| ActionSystem routes to `CombatSystem.handle_action()` | ActionSystem → CombatSystem | Facade → Facade | **Handler registry** |
| `ReactionCollector.collect()` scans `target.reactions[]` | CombatSystem → ReactionCollector | Facade → Adapter | Internal child call |
| `Arbitrator.resolve()` computes RP for both sides | CombatSystem → Arbitrator | Facade → Infrastructure | Internal child call |
| `&"get_rp_bonus"` hook fires per unit | Arbitrator → Unit → PassiveSystem | Infra → Facade → Core | **Hook** |
| `ConditionResult` produced | Arbitrator | Infrastructure | Core data type |
| If reactor wins: `reaction.execute_async()` — show icon | CombatSystem → BaseReaction | Facade → Core | Direct call |
| `EffectExecutor.execute()` runs effect pipeline | CombatSystem → EffectExecutor | Facade → Infrastructure | Internal child call |
| `DamageEffect` → `Unit.take_damage()` | EffectExecutor → Unit | Infra → Facade | Direct call |
| `&"on_take_damage"` hook fires | Unit → PassiveSystem | Facade → Core | **Hook** |
| `ArmorPassive` reduces `modified_damage` | PassiveSystem | Core | Writes `TakeDamageContext` |
| If hp ≤ 0: `&"on_death_check"` hook fires | Unit → PassiveSystem | Facade → Core | **Hook** |
| `LastStandPassive` sets `prevent_death = true` | PassiveSystem | Core | Writes `DeathCheckContext` |
| `PassiveScanner` fires `&"on_combat_resolved"` on both units | CombatSystem → PassiveScanner → Unit | Facade → Adapter → Facade | **Hook** |
| `ThornsPassive` submits counter-damage action | PassiveSystem → CombatSystem | Core → Facade | Direct call |

> Core coupling: `ConditionResult` is a shared Core data type flowing from `Arbitrator` through `EffectExecutor` into `ActionContext`. Passives modify data in-place via typed `PassiveContext` objects — no system-to-system direct reference.

---

### 3. Turn Management

| Step | System | Layer | Coupling |
|------|--------|-------|----------|
| `TurnSystem.start_battle()` | TurnSystem | Facade | — |
| State chain: BattleStart → FactionTurnStart → … → UnitActing | TurnSystem | Infrastructure | Each state calls `go_to_X()` |
| `UnitActingState` emits `activated(unit, token)` | TurnSystem | Infra → Facade | **Signal** |
| `ActionSystem.on_unit_acting()`: team 0 → show menu; else → emit `ai_turn_requested` | ActionSystem | Facade | Internal routing |
| Player or AI completes all actions | ActionSystem | Facade | — |
| `unit_turn_finished` signal emitted | ActionSystem | Facade | **Signal** |
| `UnitActingState.release_unit_turn()` — token released | TurnSystem | Infra | Receives signal (CONNECT_DEFERRED) |
| `UnitTurnEndState._transition()`: query next unit or deferred | TurnSystem | Facade + Infra | Navigation query |
| All units done → FactionTurnEnd → next faction or TurnEnd | TurnSystem | Infrastructure | State chain |
| `unit_died` → `GoalSystem.goal_achieved` → `TurnSystem.trigger_battle_end()` | GoalSystem → TurnSystem | Facade → Facade | **Signal** |

> Decoupling note: `CONNECT_DEFERRED` on `unit_turn_finished` breaks the synchronous call stack. ActionSystem does not know `UnitActingState` exists; `UnitActingState` does not know ActionSystem exists.

---

### 4. Wait / Deferred Turn

| Step | System | Layer | Coupling |
|------|--------|-------|----------|
| Player presses hotkey 4 | InputSystem → ActionSystem | Facade → Facade | **Signal** |
| `WaitAction.is_target_resolved()` = true → execute immediately | ActionSystem → WaitAction | Facade → Core | Direct call |
| ActionSystem routes to `TurnSystem.handle_action(WaitAction)` | ActionSystem → TurnSystem | Facade → Facade | **Handler registry** |
| `ActionResult.DEFERRED` returned | TurnSystem | Facade | Core data type |
| ActionSystem detects DEFERRED → `TurnSystem.defer_unit(unit)` | ActionSystem → TurnSystem | Facade → Facade | Direct call |
| `unit.has_waited = true`; `WaitAction.can_execute()` returns false for the rest of the faction turn | Unit / WaitAction | Core | Internal state |
| After all regular units finish: `get_next_deferred_unit_in_faction()` | TurnSystem | Facade | Navigation query |
| `go_to_unit_turn(deferred_unit)`: `reset_turn()` is skipped | TurnSystem | Facade | Internal — no reset means statuses tick only once per full round |

---

### 5. Guard + Reaction Trigger

| Step | System | Layer | Coupling |
|------|--------|-------|----------|
| Player presses hotkey 3 | InputSystem → ActionSystem | Facade → Facade | **Signal** |
| `TurnSystem.handle_action(GuardAction)` → `unit.apply_status("guarding", 1)` | TurnSystem → Unit | Facade → Facade | Direct call |
| Enemy selects Attack targeting the guarded unit | CombatSystem | Facade | — |
| `ReactionCollector.collect()`: `BlockReaction.can_trigger()` checks `has_status("guarding")` + `action_id == "attack"` | ReactionCollector → Unit | Adapter → Facade | Direct call |
| `Arbitrator.resolve()`: BlockReaction base_rp=8 vs AttackAction base_rp | Arbitrator | Infrastructure | Core data |
| If reactor wins: `BlockReaction.execute_async()` — show block icon for 3s | CombatSystem → BlockReaction | Facade → Core | Direct call |
| `EffectExecutor` takes on_miss branch — no damage applied | EffectExecutor | Infrastructure | Reads `ConditionResult` (Core) |
| Next turn start: `reset_turn()` calls `tick_and_expire()` — "guarding" expires | TurnSystem → Unit → StatusEffectReceiver | Facade chain | Direct calls |

---

### 6. AI Turn

| Step | System | Layer | Coupling |
|------|--------|-------|----------|
| `UnitActingState` activates with an enemy unit | TurnSystem | Infra | — |
| `ActionSystem.on_unit_acting()`: team ≠ 0 → emit `ai_turn_requested(unit)` | ActionSystem | Facade | **Signal** |
| `AISystem.on_ai_turn_requested()`: await 0.4s delay | AISystem | Facade | — |
| AISystem finds child `FactionAIBrain` matching `unit.team` | AISystem | Facade | Scans child nodes |
| `AISystem.build_context()` → fresh `AIContext` snapshot | AISystem | Facade → Core | Internal |
| `BanditBrain.decide()`: check range → fill `AttackAction` or `MoveAction` with target data | BanditBrain | Infrastructure | Reads `AIContext` (Core) |
| `action_system.on_action_chosen(action)` | AISystem → ActionSystem | Facade → Facade | Direct call |
| `action.is_target_resolved()` = true → execute immediately, skip AWAITING_TARGET | ActionSystem | Facade | Core contract |
| If AP > 0 after action: emit `ai_turn_requested` again | ActionSystem | Facade | **Signal (self-loop)** — natural multi-action turn |

---

### 7. Passive Hooks (Cross-Cutting)

Passives intercept at seven points across the combat and turn pipeline. No system is modified when a new passive is added — each passive declares its hook IDs; `Unit` routes them.

| Hook ID | When it fires | Who fires it | Systems involved |
|---------|--------------|--------------|-----------------|
| `&"get_move_points"` | Before showing move range | `Unit.get_effective_move_points()` | `MoveAction.on_selected` → Unit → PassiveSystem |
| `&"get_attack_range"` | Before showing attack range | `Unit.get_effective_attack_range()` | `CombatAction.on_selected` → Unit → PassiveSystem |
| `&"get_rp_bonus"` | During RP arbitration | `Arbitrator._compute_rp()` | Arbitrator → Unit → PassiveSystem |
| `&"on_take_damage"` | Before damage is applied | `Unit.take_damage()` | DamageEffect → Unit → PassiveSystem |
| `&"on_death_check"` | When hp ≤ 0 | `Unit.take_damage()` | DamageEffect → Unit → PassiveSystem |
| `&"on_combat_resolved"` | After full combat resolution | `PassiveScanner` (post-drain) | CombatSystem → PassiveScanner → Unit → PassiveSystem |
| `&"on_unit_turn_start"` | At unit turn boundary | `TurnEffectProcessor` | TurnSystem → TurnEffectProcessor → Unit → PassiveSystem |

> Coupling pattern: all hooks use the same interface — `unit.fire_hook(id, ctx)`. Systems only know about `Unit` (Facade) and the typed `PassiveContext` (Core data type). Concrete passives are Infrastructure — adding a new passive never requires modifying any other system.

---

## Credits

| Asset | Author | Source |
|-------|--------|--------|
| **32Rogues** — character sprites and terrain tiles | Seth BB | [sethbb.itch.io/32rogues](https://sethbb.itch.io/32rogues) |
| **Raven Fantasy Icons** — action icons | Clockwork Raven | [clockworkraven.itch.io/raven-fantasy-icons](https://clockworkraven.itch.io/raven-fantasy-icons) |
