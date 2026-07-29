# Seed 调试控件 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-02

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [068_weighted_reward_random_selection.md](068_weighted_reward_random_selection.md)
- [069_run_seed_randomization.md](069_run_seed_randomization.md)
- [071_settlement_seed_display.md](071_settlement_seed_display.md)

## 目标

把 seed 复现从“脚本测试能力”推进到“手动测试 UI 能力”。测试者在界面看到异常抽牌、路线或奖励时，可以直接复制当前 seed，也可以输入 seed 重开同一局。

## UI

控制行新增 3 个控件：

- `Seed` 输入框：默认显示当前旅程 seed，也可以手动输入 seed。
- `复制 Seed`：把当前旅程 seed 写入剪贴板，并同步到输入框。
- `按 Seed 重开`：读取输入框整数，用该 seed 重新开始旅程。

输入框获得焦点时，刷新 UI 不会覆盖正在输入的内容。

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `seed_input`、`copy_seed_button`、`restart_seed_button`。
  - `_build_ui()` 在控制行加入 seed 输入框和按钮。
  - `_refresh_ui()` 在输入框未聚焦时同步当前 `run_seed`。
  - 新增 `_on_copy_seed_pressed()`。
  - 新增 `_on_restart_with_seed_pressed()`。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/battle/battle_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/data/card_definition.gd=0
res://scripts/data/effect_definition.gd=0
res://scripts/data/encounter_definition.gd=0
```

控件验证：

```text
initial_seed_ui=seed=24680 input=24680 copy_exists=true restart_seed_exists=true hand=C006,C001,C011,C011,C006
copy_seed=input=24680 last_log=已复制 Seed：24680。
restart_with_seed=seed=13579 input=13579 hand=U001,C020,C011,C006,U002 status_has_seed=true
repeat_seed=seed=13579 hand=U001,C020,C011,C006,U002
invalid_seed_log=Seed 无效：请输入整数。
```

结果说明：

- seed 输入框默认显示当前旅程 seed。
- 复制按钮能同步输入框并写入日志。
- 按 seed 重开后，同一 seed 能复现同样开局手牌。
- 非整数输入不会重开，会写入错误提示。

## 下一步

1. 结算页显示本局 seed 已完成，见 [071_settlement_seed_display.md](071_settlement_seed_display.md)。
2. 如果后续加入独立调试面板，可以把 seed 控件移动到调试区，避免正式 UI 过多。
