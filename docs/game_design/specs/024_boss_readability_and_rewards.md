# Boss 可读性与专属奖励 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [002_mvp_boss_set.md](002_mvp_boss_set.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [023_first_boss_node.md](023_first_boss_node.md)
- [025_proposal_delay_settlement.md](025_proposal_delay_settlement.md)
- [027_boss_reward_visuals.md](027_boss_reward_visuals.md)
- [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)
- [032_third_boss_blind_review.md](032_third_boss_blind_review.md)

## 目标

`B001 开题报告` 已经能作为路线末尾 Boss 进入战斗。本次补充两件事：

1. 让玩家在 Boss 战里能看懂当前意图、资源检查和阶段检查。
2. 让 Boss 胜利后不是普通加卡，而是提供更有阶段感的专属奖励。

## Boss 战可读信息

Boss 战的敌方信息区现在会显示：

- Boss 名称、当前进度和目标进度。
- 当前 Boss 意图，例如 `研究意义追问：造成 7 压力`。
- 当前意图的资源检查，例如 `至少 1 灵感`。
- 资源检查达成或未达成的结果。
- Boss 阶段检查提示。

阶段检查提示会根据距离触发点变化：

- 距离较远：提示 `进度达到 35 时，需要 2 草稿或 2 数据`。
- 距离较近：提示还差多少进度，并提醒准备 2 草稿或 2 数据。
- 已触发：提示检查已完成。

## Boss 胜利奖励

`B001 开题报告` 胜利后不再展示普通奖励卡三选一，而是展示 3 个 Boss 奖励：

| 奖励 | 类型 | 效果 |
| --- | --- | --- |
| 确定研究方向 | 局外资源 | 方法论笔记 +2 |
| 整理开题反馈 | 局外资源 | 论文碎片 +1，经验教训 +1 |
| 删去质疑噪音 | 牌组净化 | 优先移除 1 张 `S010 自我怀疑`；若没有，则移除 1 张 `S004 信息过载` |

如果选择“删去质疑噪音”但两种负面牌都不存在，则改为获得方法论笔记 +1。

设计意图：

- Boss 战胜利应明显比普通节点更有“阶段完成感”。
- 奖励既能给局外正反馈，也能改善下局体验。
- “坏结局也有资源，过 Boss 也有资源”，两条反馈都服务于再来一局。

## 实现内容

更新：

- `scripts/battle/battle_state.gd`
  - 新增 `get_boss_readability_text()`。
  - 新增 `get_boss_phase_hint_text()`。
  - 新增 `remove_card_everywhere()`，用于 Boss 奖励从牌组和战斗牌堆中移除负面牌。
  - 新增 Boss 意图、条件和效果的中文格式化辅助函数。
- `scripts/ui/battle_test_scene.gd`
  - Boss 战敌方信息区显示当前意图、检查和阶段提示。
  - Boss 胜利后展示专属奖励三选一。
  - 新增 `get_last_boss_reward_result_text()`，方便自动化验证。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
res://scripts/battle/battle_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/run/run_settlement.gd=0
```

Boss 可读文本验证：

```text
enemy_intent=研究意义追问：造成 7 压力
readability=当前意图：研究意义追问：造成 7 压力
检查：至少 1 灵感；未达成：加入 自我怀疑
确定题目检查：进度达到 35 时，需要 2 草稿或 2 数据。
phase_hint_start=确定题目检查：进度达到 35 时，需要 2 草稿或 2 数据。
phase_hint_near=确定题目检查临近：还差 5 进度，准备 2 草稿或 2 数据。
deck_has_status=true
```

Boss UI 奖励验证：

```text
route_ids=N001,N002,E004,N003,N004,B001
boss_enemy_has_intent=true
boss_enemy_has_phase=true
boss_has_s010_before=true
boss_reward_options=boss_direction,boss_feedback,boss_remove_status
boss_reward_buttons=3
boss_reward_label=开题报告通过。选择 1 项 Boss 奖励：
select_remove_status=true
boss_reward_result=删除负面牌：移除 自我怀疑。
boss_has_s010_after=false
settlement_visible=true
settlement_outcome=route_completed
settlement_paper_fragments=2
settlement_methodology=10
settlement_save_error=0
```

## 结果说明

- Boss 战不再只显示简单压力数值，而是能解释当前意图和资源检查。
- Boss 阶段检查有提前提示，玩家可以围绕草稿和数据做准备。
- Boss 胜利奖励已经与普通节点奖励区分开。
- Boss 奖励选择后能正常完成路线，并进入阶段结算。

## 下一步

1. `B001` 失败结算：开题延期已完成，见 [025_proposal_delay_settlement.md](025_proposal_delay_settlement.md)。
2. Boss 胜利奖励视觉区分已完成，见 [027_boss_reward_visuals.md](027_boss_reward_visuals.md)。
3. `B002 中期考核` 已完成首版实现，见 [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)。
4. `B003 盲审专家` 已完成首版实现，见 [032_third_boss_blind_review.md](032_third_boss_blind_review.md)。
