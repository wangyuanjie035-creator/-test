# Boss 奖励视觉区分 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [024_boss_readability_and_rewards.md](024_boss_readability_and_rewards.md)
- [026_settlement_visual_hierarchy.md](026_settlement_visual_hierarchy.md)
- [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)
- [030_b002_reward_pool.md](030_b002_reward_pool.md)
- [032_third_boss_blind_review.md](032_third_boss_blind_review.md)

## 目标

Boss 胜利奖励不再复用普通节点的文字提示和普通按钮排布，而是独立显示为“阶段奖励”面板。

这样玩家能更明确地感到：

- 这是 Boss 战胜利后的特殊时刻。
- 三个奖励不是普通加卡，而是局外成长或牌组净化。
- 选择后会立刻生效，并进入下一 Boss 节点或阶段结算。

## UI 结构

新增 `boss_reward_panel`，仅在 Boss 胜利奖励流程中显示。

面板内容：

| 节点 | 用途 |
| --- | --- |
| `boss_reward_title_label` | 显示当前 Boss 通过标题，例如 `开题报告通过`、`中期考核通过` 或 `Boss 奖励已选择` |
| `boss_reward_description_label` | 显示奖励说明或已选择结果 |
| `boss_reward_container` | 显示 3 个 Boss 奖励按钮 |

普通节点胜利仍使用原来的：

- `reward_label`
- `reward_container`

## 奖励按钮

Boss 奖励按钮保留三项：

| 奖励 | 类型 | 效果 |
| --- | --- | --- |
| 确定研究方向 | 局外资源 | 方法论笔记 +2 |
| 整理开题反馈 | 局外资源 | 论文碎片 +1，经验教训 +1 |
| 删去质疑噪音 | 牌组净化 | 移除 1 张自我怀疑或信息过载 |

按钮使用专属边框色：

- `确定研究方向`：蓝色，强调方向确认。
- `整理开题反馈`：绿色，强调成长沉淀。
- `删去质疑噪音`：暖色，强调清理负面。

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `boss_reward_panel`、`boss_reward_title_label`、`boss_reward_description_label`、`boss_reward_container`。
  - 新增 `get_boss_reward_panel_visible()`、`get_boss_reward_title_text()`、`get_boss_reward_description_text()` 供验证使用。
  - Boss 胜利时调用 `_show_boss_reward_options()`。
  - Boss 奖励选择后调用 `_show_boss_reward_result()`。
  - 普通节点奖励仍使用旧布局。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
battle_test_scene=0
```

Boss 奖励面板验证：

```text
boss_panel_visible=true
boss_panel_title=开题报告通过
boss_panel_description=选择 1 项阶段奖励。局外成长会进入本次结算，牌组净化会立刻生效。
reward_button_count=3
normal_reward_label=
boss_button_texts=确定研究方向/局外资源/方法论笔记 +2|整理开题反馈/局外资源/论文碎片 +1，经验教训 +1|删去质疑噪音/牌组净化/移除 1 张自我怀疑或信息过载
boss_container_visible=true
select_feedback=true
result_panel_visible=true
result_title=Boss 奖励已选择
result_description=整理开题反馈：论文碎片 +1，经验教训 +1。
result_button_count=0
settlement_visible=true
settlement_outcome=route_completed
```

普通奖励不回归验证：

```text
normal_boss_panel_visible=false
normal_reward_label=节点通过。选择 1 张卡加入牌组：
normal_reward_button_count=3
normal_first_reward_text=精读文献/费用 1/获得 2 灵感；若本回合打过文献牌，抽 1 张牌。
```

## 结果说明

- Boss 胜利奖励拥有独立面板和标题。
- 选择 Boss 奖励后，面板会显示已选择结果，按钮消失。
- 普通节点奖励布局未改变。
- `get_reward_button_count()` 仍能统计当前可见奖励按钮。

## 下一步

1. `B002` 专属奖励池已完成，见 [030_b002_reward_pool.md](030_b002_reward_pool.md)。
2. `B003` 已接入并复用该奖励面板，见 [032_third_boss_blind_review.md](032_third_boss_blind_review.md)。
3. 后续可把普通奖励卡也改成更卡牌化的视觉样式。
