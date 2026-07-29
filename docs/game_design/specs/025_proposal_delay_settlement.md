# 开题延期失败结算 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [013_run_settlement.md](013_run_settlement.md)
- [023_first_boss_node.md](023_first_boss_node.md)
- [024_boss_readability_and_rewards.md](024_boss_readability_and_rewards.md)
- [026_settlement_visual_hierarchy.md](026_settlement_visual_hierarchy.md)
- [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)

## 目标

`B001 开题报告` 失败时不再走普通 `burnout`，而是进入专属坏结局 `proposal_delayed`：开题延期。

设计重点不是惩罚玩家，而是把失败转化为下一次尝试的准备：

- 玩家看见明确叙事：不是“游戏结束”，而是“开题没有一次通过”。
- 局外资源继续增长，符合“坏结局也有正反馈”的方向。
- 通过 Boss 与未通过 Boss 的结算仍然有明显差异。

## 触发条件

当玩家处于 `B001 开题报告` Boss 战，并且敌方回合后精力降到 0 时：

```text
outcome_id = proposal_delayed
title = 开题延期
```

普通战斗或事件导致精力归零时，仍然使用原本的：

```text
outcome_id = burnout
title = 精力耗尽
```

## 资源规则

`proposal_delayed` 沿用阶段结算的基础资源：

- `经验教训 = max(1, completed_nodes * 2 + deck_growth)`
- `方法论笔记 = completed_nodes + floor(deck_growth / 2)`

然后额外获得：

| 资源 | 数量 | 用意 |
| --- | --- | --- |
| 经验教训 | +3 | 专家追问变成复盘材料 |
| 方法论笔记 | +1 | 题目和方法问题被具体暴露 |
| 心理韧性 | +1 | 延期不是终点，下一次还能调整 |
| 黑历史档案 | +1 | 记录一次典型坏结局 |
| 论文碎片 | +1 | 仅当 Boss 进度达到目标一半及以上 |

设计边界：

- 不直接给予 Boss 胜利奖励。
- 不自动净化负面牌。
- 如果打到一半以上，说明已有部分材料沉淀，因此额外给 1 论文碎片。

## 实现内容

更新：

- `scripts/run/run_settlement.gd`
  - 新增 `proposal_delayed` 标题和描述。
  - 新增 `proposal_delayed` 局外资源计算分支。
- `scripts/ui/battle_test_scene.gd`
  - 新增 `_get_failure_settlement_reason()`。
  - Boss `B001` 精力归零时进入 `proposal_delayed`。
  - 普通战斗精力归零仍进入 `burnout`。
  - 结算日志新增“开题延期，进入阶段结算。”。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
res://scripts/run/run_settlement.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

Boss 开局失败验证：

```text
settlement_visible=true
settlement_outcome=proposal_delayed
summary=开题延期
这次开题没有一次通过，但问题已经被具体地暴露出来。导师和专家的追问会沉淀成下一次更稳的准备。
完成节点：5/6 | 当前牌组：17 张 | 精力：0/50
获得局外资源：经验教训 +15，方法论笔记 +7，心理韧性 +1，论文碎片 +0，黑历史档案 +1。
lessons=15
methodology=7
resilience=1
paper=0
black_history=1
save_error=0
next_available=false
log_tail=开题延期，进入阶段结算。
```

普通失败不回归验证：

```text
normal_outcome=burnout
normal_visible=true
```

Boss 推进过半失败验证：

```text
half_outcome=proposal_delayed
half_paper=1
half_summary_has_delay=true
```

## 结果说明

- `B001` 失败现在拥有独立结算身份。
- 普通精力耗尽仍保持原有 `burnout` 逻辑。
- Boss 失败会保存局外资源，继续支撑下一局正反馈。
- 结算后不会继续出现下一节点入口。

## 下一步

1. 结算区域视觉层级已完成，见 [026_settlement_visual_hierarchy.md](026_settlement_visual_hierarchy.md)。
2. 给 Boss 胜利奖励增加更强的视觉区分。
3. `B002 中期考核` 已完成首版实现，见 [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)。
