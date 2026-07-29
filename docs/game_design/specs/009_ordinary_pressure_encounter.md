# 普通压力节点规格 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-26

关联文档：

- [007_minimal_battle_state.md](007_minimal_battle_state.md)
- [008_battle_test_ui.md](008_battle_test_ui.md)

## 目标

把战斗测试界面里的固定 6 点压力迁移到节点数据，让普通战斗从一开始就走数据驱动路线。

## 首个节点

| 字段 | 值 |
| --- | --- |
| id | `N001` |
| 名称 | 普通压力 |
| 阶段 | `master_1` |
| 目标进度 | 40 |
| 每回合压力 | 6 |
| 意图名 | 赶进度 |

## 实现内容

新增：

- `scripts/data/encounter_definition.gd`
- `data/encounters/n001_ordinary_pressure.tres`

更新：

- `scripts/data/game_data_catalog.gd` 增加 `load_encounters_by_id()`。
- `scripts/battle/battle_state.gd` 增加节点目标、压力意图、胜利判断和 `resolve_enemy_turn()`。
- `scripts/ui/battle_test_scene.gd` 显示节点面板，并从 `N001` 读取目标进度和压力。
- `scripts/tools/validate_battle_state.gd` 加载并验证 `N001`。

## 验收标准

- `GameDataCatalog` 能加载 `N001`。
- `BattleState` 能显示目标进度 40 和每回合压力 6。
- UI 能显示节点名称和敌方意图。
- 结束回合通过 `resolve_enemy_turn()` 扣除精力。
- 当进度达到目标后，结束回合按钮和手牌按钮禁用。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

节点加载和 UI 验证：

```text
encounter_count=1
encounter_name=普通压力
encounter_target=40
encounter_pressure=6
ui_hand_initial=5
ui_enemy_text=普通压力 | 目标进度 0/40 | 意图：赶进度：造成 6 压力
ui_play_first=true
ui_turn_after_end=2
ui_vitality_after_end=44
ui_hand_after_end=5
```

胜利分支验证：

```text
victory_before=false
play_experiment=true
progress_after=40
victory_after=true
pressure_after_victory=0
vitality_after_victory=50
```

结果说明：

- `N001` 能通过 `GameDataCatalog.load_encounters_by_id()` 正确加载。
- UI 已显示节点名称、目标进度和敌方意图。
- 结束回合使用节点数据里的 6 点压力。
- 达到 40 进度后判定节点通过，敌方不再造成压力。

## 下一步

1. 奖励选择界面已完成，见 [010_reward_selection.md](010_reward_selection.md)。
2. 下一步增加“下一节点”按钮，形成普通节点循环。
3. 再接入开题报告 Boss。
