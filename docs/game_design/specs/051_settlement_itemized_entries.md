# 结算页条目化信息 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-01

关联文档：

- [049_settlement_unlock_highlight.md](049_settlement_unlock_highlight.md)
- [050_settlement_section_layout.md](050_settlement_section_layout.md)
- [052_settlement_entry_rows.md](052_settlement_entry_rows.md)

## 目标

让结算页每个分区更像“可扫读清单”，而不是一整行压缩文本。

本次调整只改文本格式，不新增复杂 UI 组件：

- `资源变化`：每项资源单独一行。
- `新解锁`：每个解锁种子单独一行。
- `下局带入`：每张带入卡单独一行，并显示费用和效果摘要。

## 显示示例

```text
资源变化
经验教训 +17
方法论笔记 +8
心理韧性 +4
论文碎片 +6
黑历史档案 +1

新解锁
自我照护种子
返修策略种子
返修矩阵种子

下局带入
自我照护（0费）：恢复 3 精力，本牌消耗。
返修策略（1费）：获得 5 进度和 1 草稿。
返修矩阵（1费）：获得 6 进度和 1 方法论笔记，本牌消耗。
```

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - `_format_settlement_resources()` 改为按 `\n` 分行。
  - `_format_settlement_new_unlocks()` 改为按 `\n` 分行。
  - `_format_settlement_new_carryover()` 改为按 `\n` 分行。
  - 新增 `_format_unlock_carry_card_summary()`，显示 `卡名（费用）：效果摘要`。
  - 新增 `_get_unlock_carry_card_id()`，集中维护解锁到带入卡的映射。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
res://scripts/ui/battle_test_scene.gd=0
res://scripts/run/meta_progression_state.gd=0
res://scripts/run/route_state.gd=0
res://scripts/run/run_settlement.gd=0
res://scripts/data/game_data_catalog.gd=0
```

B008 失败条目化验证：

```text
settlement_outcome=supplementary_defense_failed
settlement_title=补答辩再延期
resource_text=经验教训 +17
方法论笔记 +8
心理韧性 +4
论文碎片 +6
黑历史档案 +1
unlock_text=自我照护种子
返修策略种子
返修矩阵种子
carryover_text=自我照护（0费）：恢复 3 精力，本牌消耗。
返修策略（1费）：获得 5 进度和 1 草稿。
返修矩阵（1费）：获得 6 进度和 1 方法论笔记，本牌消耗。
save_error=0
```

无新解锁隐藏验证：

```text
no_new_unlock_text=
no_new_carryover_text=
```

## 下一步

1. 文本条目已升级成真实 UI 行，见 [052_settlement_entry_rows.md](052_settlement_entry_rows.md)。
