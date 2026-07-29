# 结算新解锁突出显示 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-01

关联文档：

- [014_meta_progression_save.md](014_meta_progression_save.md)
- [016_meta_carryover_preview.md](016_meta_carryover_preview.md)
- [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md)
- [050_settlement_section_layout.md](050_settlement_section_layout.md)
- [051_settlement_itemized_entries.md](051_settlement_itemized_entries.md)

## 目标

让玩家在结算页第一眼看到“这次坏结局或通关给下一局带来了什么新东西”，而不是把新解锁埋在存档摘要里。

## 显示规则

当 `settlement_save.new_unlocks` 非空时，在结算资源下方显示独立的新解锁分区和下局带入分区：

```text
新解锁
自我照护种子、返修策略种子、返修矩阵种子

下局带入
自我照护、返修策略、返修矩阵
```

当没有新解锁时，该区域隐藏，避免每次结算都产生视觉噪音。

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `settlement_unlock_label`。
  - 新增 `get_settlement_unlock_text()` 供自动验证。
  - 新增 `_format_settlement_new_unlocks()`。
  - 新增 `_get_unlock_carry_card_display_name()`，把当前解锁 ID 映射到下一局实际带入卡名。
  - 后续拆分出 `settlement_carryover_label`，见 [050_settlement_section_layout.md](050_settlement_section_layout.md)。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
res://scripts/ui/battle_test_scene.gd=0
res://scripts/run/meta_progression_state.gd=0
```

B008 失败触发新解锁验证：

```text
settlement_outcome=supplementary_defense_failed
settlement_title=补答辩再延期
unlock_text=自我照护种子
返修策略种子
返修矩阵种子
carryover_text=自我照护（0费）：恢复 3 精力，本牌消耗。
返修策略（1费）：获得 5 进度和 1 草稿。
返修矩阵（1费）：获得 6 进度和 1 方法论笔记，本牌消耗。
```

无新解锁隐藏验证：

```text
no_new_unlock_text=
no_new_carryover_text=
```

## 下一步

1. 结算页分区布局已接入，见 [050_settlement_section_layout.md](050_settlement_section_layout.md)。
2. 分区内容条目化已完成，见 [051_settlement_itemized_entries.md](051_settlement_itemized_entries.md)。
3. 后续可以把该区域升级成带图标的小条目，例如每个新解锁显示卡名、费用和一句效果摘要。
