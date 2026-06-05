# CLAUDE.md — Tactical RPG Project

## Project Overview

Godot 4.6 · GDScript · Tactical RPG (Into the Breach / XCOM style) · Grid-based turn-based combat.

Assets: `Assets/Character and Tile/32rogues/` (tiles, chars) · `Assets/Icon/` (action icons fb593–fb862)

Xem memory files để biết scene tree hiện tại, system API, và pending tasks.

---

## Nguyên tắc kiến trúc cốt lõi

### 1. Core / Adapter / Visual separation

```
Core Logic (data + algorithm, không biết Godot Node)
     ↓
Adapter Layer (bridge, thay thế được)
     ↓
Visual Layer (TileMap, Sprite2D, Node2D...)
```

Tương lai có thể swap sang isometric/3D → chỉ cần thay Adapter + Visual, Core giữ nguyên.

### 2. Scene-tree-first

Mọi system và game object quan trọng phải là Node đặt sẵn trong `.tscn` — không `.new()` + `add_child()` từ script của object khác.

```
[ĐÚNG]  @onready var move_system: MoveSystem = $ActionHolder/MoveSystem
[SAI]   move_system = MoveSystem.new(); add_child(move_system)
```

### 3. Manager pattern

Mỗi category entity có một Manager Node độc lập — `UnitManager`, `HealthUIManager`, `FloatingTextManager`. Manager là parent node của tất cả entities nó quản lý. Mỗi Manager chỉ có một trách nhiệm.

### 4. Resource-driven data

Stats, map layout, action definitions → `.tres` Resource. Manager đọc Resource → populate Node. Không hardcode trong `_ready()`.

### 5. UI / Logic separation

Gameplay systems không reference UI trực tiếp. Communicate qua signals. Compositor (Demo.gd) wire cả 2 chiều.

```
[ĐÚNG]  action_system.show_menu_requested.emit(unit, pos)  → ActionMenu.show_for_unit()
[SAI]   action_system._menu.show_for_unit(unit, pos)
```

Mọi UI node đặt dưới `UIManager`. Future: `HealthUIManager`, `FloatingTextManager` là children của `UIManager`.

### Ngoại lệ chấp nhận được

OK tạo bằng code: `Button`/`Label` trong dynamic list · `Tween`/`Timer` · `Resource`/`RefCounted` subclass · Manager spawning entities nó quản lý.

---

## Ghi chú kỹ thuật

- Godot 4.6.2 stable · GL Compatibility + D3D12 · GDScript
- Communication: Signal (không direct reference giữa systems)
- Grid coordinates: `Vector2i` (integer) — không dùng `Vector2` float
