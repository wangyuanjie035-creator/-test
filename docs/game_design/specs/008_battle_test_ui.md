# 战斗测试界面规格 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-26

关联文档：

- [007_minimal_battle_state.md](007_minimal_battle_state.md)
- [006_godot_data_layer_implementation.md](006_godot_data_layer_implementation.md)
- [020_route_map_and_event_feedback.md](020_route_map_and_event_feedback.md)

## 目标

创建一个极简 Godot 场景，把 `BattleState` 连接到可点击 UI，用来验证手牌和资源流。

## 界面内容

首版只做测试界面，不追求最终视觉风格。

必须显示：

- 当前回合。
- 精力、防护、行动点、进度。
- 灵感、数据、草稿、经费、声望。
- 抽牌堆、手牌、弃牌堆、消耗堆数量。
- 当前手牌按钮。
- 结束回合按钮。
- 重开测试按钮。
- 简单日志。

## 交互规则

- 点击可用手牌：调用 `BattleState.play_card_by_index()`。
- 行动点不足或不可打出的状态牌：按钮禁用。
- 点击结束回合：弃掉手牌，根据当前节点意图承受压力，开始新回合。
- 点击重开测试：重新加载 `D001` 初始牌组。

## 暂不做

- 正式美术。
- 卡牌拖拽。
- 敌人 UI。
- Boss 意图。
- 动画和音效。
- 卡牌选择发现界面。

## 验收标准

- Godot editor executor 能加载并实例化 `res://scenes/battle_test_scene.tscn`。
- 场景根节点脚本能创建 UI。
- 初始化后手牌按钮数量为 5。
- 点击一张可用卡后，弃牌堆增加且资源刷新。
- 结束回合后能进入下一回合并重新抽牌。

## 实现记录

新增文件：

| 文件 | 用途 |
| --- | --- |
| `scenes/battle_test_scene.tscn` | 极简战斗测试场景 |
| `scripts/ui/battle_test_scene.gd` | 运行时构建测试 UI 并连接 `BattleState` |

更新文件：

| 文件 | 改动 |
| --- | --- |
| `project.godot` | 设置 `run/main_scene` 为 `res://scenes/battle_test_scene.tscn` |

当前界面支持：

- 初始化 `D001` 初始牌组。
- 显示回合、精力、防护、行动点、进度和研究资源。
- 显示抽牌堆、手牌、弃牌堆和消耗堆数量。
- 点击手牌按钮打出卡牌。
- 行动点不足或不可打出的卡牌会禁用按钮。
- 结束回合后根据当前节点数据承受压力，并进入下一回合。
- 重开测试。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

验证输出：

```text
hand_buttons_initial=5
play_first=true
hand_buttons_after_play=5
turn_after_end=2
hand_buttons_after_turn=5
vitality_after_turn=44
main_scene=res://scenes/battle_test_scene.tscn
```

结果说明：

- 场景可加载，根节点脚本可执行。
- UI 初始化后生成 5 个手牌按钮。
- 点击第一张可用牌后按钮刷新正常，没有重复累加。
- 结束回合后进入第 2 回合。
- 普通压力节点的 6 点压力来自 `N001` 数据，并正确扣除精力，精力从 50 变为 44。
- 项目主场景已指向战斗测试场景。

## 下一步

1. 普通压力节点面板已完成，见 [009_ordinary_pressure_encounter.md](009_ordinary_pressure_encounter.md)。
2. 奖励选择界面已完成，见 [010_reward_selection.md](010_reward_selection.md)。
3. 路线条和事件结果反馈已完成，见 [020_route_map_and_event_feedback.md](020_route_map_and_event_feedback.md)。
