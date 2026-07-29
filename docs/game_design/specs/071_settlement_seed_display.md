# 结算页 Seed 显示 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [026_settlement_visual_hierarchy.md](026_settlement_visual_hierarchy.md)
- [052_settlement_entry_rows.md](052_settlement_entry_rows.md)
- [069_run_seed_randomization.md](069_run_seed_randomization.md)
- [070_seed_debug_controls.md](070_seed_debug_controls.md)

## 目标

让结算页也显示本局 `run_seed`。玩家或测试者在结算时截图反馈，就能直接带上复现信息，不需要回到战斗状态栏或日志里单独找 seed。

## 显示规则

- 进入任意结算时，当前 `run_seed` 写入本次 `settlement` 字典。
- 结算统计行格式调整为：
  - `Seed x | 节点 a/b | 牌组 n 张 | 精力 v/m`
- 这只影响当前结算显示和脚本验证，不改变局外存档的资源结算规则。

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - `_complete_run()` 在 `RUN_SETTLEMENT.build()` 后写入 `settlement["run_seed"]`。
  - `_format_settlement_stats()` 在统计行前缀显示 `Seed x`。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`
- 测试存档：`user://codex_seed_settlement_test.json`

脚本编译验证：

```text
res://scripts/battle/battle_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/run/run_settlement.gd=0
res://scripts/run/route_state.gd=0
res://scripts/run/meta_progression_state.gd=0
res://scripts/data/game_data_catalog.gd=0
```

结算 Seed 验证：

```text
settlement_seed=424242
settlement_stats=Seed 424242 | 节点 0/8 | 牌组 16 张 | 精力 50/50
stats_has_seed=true
settlement_visible=true
```

结果说明：

- 指定 seed 进入结算后，`settlement` 字典保留 `run_seed`。
- 结算统计行可以直接看到 `Seed 424242`。
- 结算页可见状态正常。

## 下一步

1. 如果后续制作正式结算截图/反馈按钮，可以把 seed 一并写进反馈 payload。
2. 如果 UI 控制行迁移到调试面板，结算页 seed 仍应保留，作为手测截图的低成本复现信息。
