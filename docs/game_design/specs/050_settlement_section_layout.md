# 结算页分区布局 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-01

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [026_settlement_visual_hierarchy.md](026_settlement_visual_hierarchy.md)
- [049_settlement_unlock_highlight.md](049_settlement_unlock_highlight.md)
- [051_settlement_itemized_entries.md](051_settlement_itemized_entries.md)
- [052_settlement_entry_rows.md](052_settlement_entry_rows.md)

## 目标

把结算页从“连续文本摘要”整理成更容易扫读的分区：

```text
标题 / 描述 / 节点统计
资源变化
新解锁
下局带入
存档摘要
```

这样玩家先看到本局得到了什么，再看到是否解锁新内容，以及下一局会实际带入哪些卡。

## 显示规则

| 分区 | 显示条件 | 内容 |
| --- | --- | --- |
| 资源变化 | 始终显示 | 本次结算获得的局外资源 |
| 新解锁 | `settlement_save.new_unlocks` 非空 | 解锁种子显示名 |
| 下局带入 | 新解锁能映射到带入卡 | 下一局实际带入的卡名 |
| 存档摘要 | 存档结果非空 | 累计资源、结算次数和存档状态 |

首版不在结算卡内再嵌套卡片，只使用标题 Label 和内容 Label 分区，避免界面层级过重。

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `settlement_resources_title_label`。
  - 新增 `settlement_unlock_title_label`。
  - 新增 `settlement_carryover_title_label` 与 `settlement_carryover_label`。
  - 新增 `get_settlement_carryover_text()` 供自动验证。
  - `_format_settlement_resources()` 改为只返回资源内容，不再把标题混进正文。
  - `_format_settlement_new_unlocks()` 只返回新解锁名称。
  - 新增 `_format_settlement_new_carryover()` 和 `_get_settlement_new_unlock_ids()`。

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

B008 失败分区验证：

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
no_new_resource_text=经验教训 +20
方法论笔记 +10
心理韧性 +4
论文碎片 +6
黑历史档案 +1
no_new_unlock_text=
no_new_carryover_text=
```

## 下一步

1. 分区内容已条目化，见 [051_settlement_itemized_entries.md](051_settlement_itemized_entries.md)。
2. 分区内容已升级为真正的 UI 行，见 [052_settlement_entry_rows.md](052_settlement_entry_rows.md)。
