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

## Post-Implementation Review (áp dụng mọi thay đổi)

Sau mỗi lần implement xong, **trước khi báo cáo hoàn thành**, nêu 1–2 rủi ro khả thi nhất từ checklist dưới. Không cần báo cáo đầy đủ — chỉ cần đủ để nhận ra vấn đề trước khi nó trở thành bug trong production.

**Checklist rủi ro:**

| Category | Câu hỏi |
|---|---|
| **Frame-loop** | Có iteration/allocation trong `_process()` hoặc hot path không? N entities × M operations/frame = N×M calls? |
| **Memory / Lifecycle** | Signal connect mà không disconnect? Node giữ ref đến node đã `queue_free()`? Array tích lũy mà không clear? |
| **Coupling** | Type switch (`is MoveAction`, `is CombatAction`)? System gọi trực tiếp method của system khác thay vì signal? |
| **Contract / Boundary** | Method nhận input từ ngoài — validate chưa? Silent fail hay crash rõ ràng? |
| **Scale** | Còn đúng với 50 units? N² ẩn trong loop tưởng O(N)? Gọi `find_path()` bao nhiêu lần/frame? |
| **OCP** | Thêm action type / unit type / passive mới có phải sửa file này không? |

**Cách trình bày:** Một dòng per rủi ro, kèm lý do cụ thể tại sao có rủi ro đó trong lần implement này. Không liệt kê toàn bộ checklist — chỉ những điểm thực sự relevant.

---

## Ghi chú kỹ thuật

- Godot 4.6.2 stable · GL Compatibility + D3D12 · GDScript
- Communication: Signal (không direct reference giữa systems)
- Grid coordinates: `Vector2i` (integer) — không dùng `Vector2` float
