# 结算页条目 UI 行 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-01

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [050_settlement_section_layout.md](050_settlement_section_layout.md)
- [051_settlement_itemized_entries.md](051_settlement_itemized_entries.md)

## 目标

把结算页的 `资源变化`、`新解锁` 和 `下局带入` 从纯文本 Label 升级为真正的 UI 行。

这样玩家在结算时可以更快扫到：

- 本局实际获得了哪些局外资源。
- 本次是否出现了新解锁。
- 新解锁会在下一局具体带入哪张卡、费用是多少、效果是什么。

## 显示规则

| 分区 | UI 行内容 | 空状态 |
| --- | --- | --- |
| 资源变化 | 资源名 + 本次增量 | 显示 `暂无` |
| 新解锁 | 解锁显示名 + `新局外成长` | 隐藏分区内容 |
| 下局带入 | 卡名 + 费用 + 效果描述 | 隐藏分区内容 |

`新解锁` 和 `下局带入` 只显示本次结算新增的内容。已经在旧存档里解锁过的内容不会重复提示，避免结算页制造错误的“又获得一次”的感觉。

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `settlement_resources_list`、`settlement_unlock_list` 和 `settlement_carryover_list` 三个 `VBoxContainer`。
  - 旧的 `settlement_resources_label`、`settlement_unlock_label` 和 `settlement_carryover_label` 保留为隐藏文本源，继续服务自动验证 getter。
  - 新增 `_populate_settlement_resource_rows()`、`_populate_settlement_unlock_rows()` 和 `_populate_settlement_carryover_rows()`。
  - 新增 `_add_settlement_entry_row()`，统一创建 `名称 / 数值 / 说明` 三段式横向条目。
  - 新增 `_get_settlement_resource_entries()`，让文本输出和 UI 行共用同一份资源条目数据。

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

B008 失败 UI 行验证：

```text
advanced_b008=true
settlement_outcome=supplementary_defense_failed
settlement_title=补答辩再延期
resource_row_count=5
unlock_row_count=3
carryover_row_count=3
unlock_list_visible=true
carryover_list_visible=true
save_error=0
```

对应隐藏文本源仍可供自动测试读取：

```text
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
```

无新解锁隐藏验证：

```text
no_new_resource_row_count=5
no_new_unlock_row_count=0
no_new_carryover_row_count=0
no_new_unlock_list_visible=false
no_new_carryover_list_visible=false
no_new_unlock_text=
no_new_carryover_text=
```

## 下一步

1. 可以继续给条目行补图标或小徽标，例如资源类型图标、卡牌费用徽标。
2. 后续若结算内容继续增多，可以把 `下局带入` 改成可展开列表，默认只展示新卡的核心信息。
