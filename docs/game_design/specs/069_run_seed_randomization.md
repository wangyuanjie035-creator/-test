# 旅程 Seed 随机化与复现入口 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-02

关联文档：

- [010_reward_selection.md](010_reward_selection.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)
- [068_weighted_reward_random_selection.md](068_weighted_reward_random_selection.md)
- [070_seed_debug_controls.md](070_seed_debug_controls.md)
- [071_settlement_seed_display.md](071_settlement_seed_display.md)
- [072_route_choice_seed_shuffle.md](072_route_choice_seed_shuffle.md)

## 目标

让每次新旅程都有独立 `run_seed`，从而影响初始洗牌、后续节点洗牌和普通节点带权随机奖励。同时提供可复现入口，方便测试者记录某一局的问题后，用同一个 seed 重新打开。

## 规则

- 正常点击重开或新局时，自动生成 1 个随机 `run_seed`。
- 测试脚本可以调用 `start_new_battle_with_seed(seed)`，指定同一个 seed 复现同一局开局。
- `run_seed` 会传入 `RouteState.setup()`，并参与路线候选洗牌和奖励随机种子计算。
- 每个战斗节点会用 `run_seed + 节点序号 + 节点类型偏移` 混合出独立战斗 seed，避免所有节点共用同一洗牌序列。
- 非 Boss 下一节点候选会使用 `run_seed` 做稳定洗牌。
- 当前 seed 会显示在状态栏、结算统计行，并写入新旅程日志第一行。

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `run_seed`。
  - `start_new_battle()` 改为生成随机 seed。
  - 新增 `start_new_battle_with_seed(seed)`。
  - 新增 `get_run_seed()`。
  - 新增 `_generate_run_seed()`、`_get_encounter_battle_seed()` 和 `_get_boss_battle_seed()`。
  - 状态栏和结算统计行前缀显示 `Seed x`。
  - 新旅程日志写入 `Seed x`。

未改变：

- 路线结构仍使用当前 `RouteState` 的默认候选列。
- 奖励权重和推荐原因不变，只是随机源从固定 seed 变成当前旅程 seed。
- 局外存档不保存 run seed；seed 仅用于本局复现和测试记录。

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

指定 seed 复现验证：

```text
seeded_a=seed=123456 hand=C006,C011,C020,C020,C011 status_has_seed=true log=新的研究生旅程开始：Seed 123456，节点 1/8，普通压力。
seeded_b=seed=123456 hand=C006,C011,C020,C020,C011 status_has_seed=true log=新的研究生旅程开始：Seed 123456，节点 1/8，普通压力。
```

随机新局验证：

```text
random_seeds=1991321386,1648555856,different=true
```

结果说明：

- 同一个指定 seed 可以复现相同开局手牌。
- 正常新局会生成不同 seed。
- 状态栏和日志都能看到当前 seed。

## 下一步

1. `复制 Seed` 和 `按 Seed 重开` UI 控件已完成，见 [070_seed_debug_controls.md](070_seed_debug_controls.md)。
2. 路线候选 seed 洗牌已完成，见 [072_route_choice_seed_shuffle.md](072_route_choice_seed_shuffle.md)。
3. 结算页显示本局 seed 已完成，见 [071_settlement_seed_display.md](071_settlement_seed_display.md)。
