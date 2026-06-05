Khởi động session làm việc cho Godot Tactical RPG project. Thực hiện theo thứ tự:

1. Đọc `project_scope.md` và `project_systems_design.md` từ memory để nắm scene tree hiện tại và pending tasks.
2. Báo cáo ngắn gọn: scene tree, pending tasks quan trọng nhất.
3. Hỏi user muốn làm gì hôm nay.

Khi làm việc trong session này, áp dụng workflow sau:

---

## Node placement workflow (khi thêm node mới hoặc refactor)

Phân loại node trước khi quyết định đặt ở đâu:

| Loại | Dấu hiệu | Đặt ở đâu |
|------|----------|-----------|
| Independent system | Domain riêng, có thể reuse | Scene tree root, @onready trong Compositor |
| Soft-dependent system | Nhận input từ system X, core độc lập | ActionHolder pattern: child của holder node |
| Logic sub-component | Không có domain riêng, chỉ phục vụ parent | Child node của parent system |
| Dynamic entity (nhiều instance) | Unit, Enemy, Projectile | Manager làm parent, Manager.spawn() |
| UI element | Hiển thị info, không biết gameplay logic | UIManager children |
| Short-lived / data | Tween, Timer, Resource | OK tạo bằng code |

## Wiring trong Compositor (Demo.gd)

```gdscript
# Gameplay → UI (signal, không direct call)
action_system.show_menu_requested.connect(action_menu.show_for_unit)

# UI → Gameplay (callbacks phải public)
action_menu.action_chosen.connect(action_system.on_action_chosen)
action_menu.menu_closed.connect(action_system.on_menu_closed)

# Cross-system
turn_system.turn_started.connect(action_system.on_turn_started)
grid_system.tile_clicked.connect(action_system._on_tile_clicked)
```

## Khi thêm system mới vào Demo.tscn

1. Tạo `.gd` script với `class_name` + `extends Node`
2. Thêm node vào `.tscn` (đúng parent theo phân loại trên)
3. Thêm `ext_resource` entry trong `.tscn`
4. Thêm `@onready` trong Demo.gd
5. Wire signals trong `_wire_systems()`
6. Cập nhật memory: `project_scope.md` (scene tree) + `project_systems_design.md` (API)

## Memory update cuối session

- `project_scope.md`: cập nhật scene tree diagram nếu thay đổi
- `project_systems_design.md`: cập nhật API, pending tasks của system vừa chỉnh
- `project_architecture_decisions.md`: ghi lý do nếu ra quyết định kiến trúc mới
- `feedback_scene_tree_first.md`: ghi rule mới nếu user correct approach
