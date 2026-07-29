# 第三个 Boss：盲审专家 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [002_mvp_boss_set.md](002_mvp_boss_set.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [033_b003_graduation_endings.md](033_b003_graduation_endings.md)
- [034_transfer_application_event.md](034_transfer_application_event.md)

## 目标

把不转博的硕士毕业线从 `B002 中期考核` 继续推进到 `B003 盲审专家`。

首版重点：

- B002 通过后不再直接结算，而是出现下一节点 `B003 盲审专家`。
- B003 使用更高目标进度和更密集的检查，表达盲审压力。
- 失败时进入专属坏结局 `盲审未过`，并保留正反馈资源。
- 胜利后进入毕业结局选择，见 [033_b003_graduation_endings.md](033_b003_graduation_endings.md)。
- 暂不实现“论证护盾”底层机制，避免过早扩大核心战斗系统改动。

## 路线接入

当前路线末段为：

```text
N004 截稿临近 -> B001 开题报告 -> B002 中期考核 -> B003 盲审专家
```

完成 `B002` 并选择 Boss 奖励后，出现下一节点候选：

```text
B003 盲审专家
```

完成 `B003` 后进入毕业结局选择，再根据选择进入对应结算。

## B003 盲审专家

| 字段 | 内容 |
| --- | --- |
| ID | `B003` |
| 名称 | 盲审专家 |
| 阶段 | 研三 Boss |
| 目标进度 | 120 |
| 开局负面 | 将 1 张 `S004 信息过载` 加入弃牌堆和牌组 |
| 阶段检查 | 进度达到 70 时触发一次“送审意见汇总”检查 |
| 失败结算 | `blind_review_failed` / 盲审未过 |

## 意图循环

| 回合 | 意图 | 首版效果 |
| --- | --- | --- |
| 1 | 创新性质疑 | 造成 10 压力；若没有灵感，加入 1 张 `S010 自我怀疑` |
| 2 | 数据充分性审查 | 若有至少 2 数据，消耗 1 数据并获得 15 进度；否则加入 1 张 `S004 信息过载` |
| 3 | 格式与规范 | 造成 6 压力，加入 1 张 `S004 信息过载` |
| 4 | 逐条反驳 | 造成 12 压力，下一次获得进度 -6 |
| 5 | 大修意见 | 加入 1 张 `S002 焦虑`，Boss 目标进度 +8 |

## 阶段检查

当进度达到 70 时触发一次“送审意见汇总”：

- 若有至少 2 声望或 4 草稿，获得 12 进度。
- 否则加入 1 张 `S001 拖延` 和 1 张 `S002 焦虑`。

B003 信息区会追加：

```text
送审准备：声望 x/2，草稿 y/4，数据 z/2。
```

设计意图：

- `声望` 表示论文和研究方向被认可的程度。
- `草稿` 表示返修和逐条回应能力。
- `数据` 用于应对“数据充分性审查”，但不会单独解决所有问题。

## 毕业结局

B003 胜利后进入毕业结局选择：

| 结局 | 条件 | outcome_id |
| --- | --- | --- |
| 优秀毕业 | 精力至少 20，且声望至少 2 | `outstanding_graduation` |
| 顺利毕业 | 精力至少 10，且声望至少 1 或草稿至少 4 | `master_graduated` |
| 擦线毕业 | 始终可选 | `narrow_graduation` |

详细实现见 [033_b003_graduation_endings.md](033_b003_graduation_endings.md)。

## 盲审未过

如果在 `B003` 中精力归零，结算为：

```text
outcome_id = blind_review_failed
title = 盲审未过
```

额外资源：

- 经验教训 +5。
- 方法论笔记 +2。
- 心理韧性 +1。
- 论文碎片 +2。
- 黑历史档案 +1。
- 若 Boss 进度达到目标一半及以上，额外获得 1 论文碎片。

## 实现内容

新增：

- `data/bosses/b003_blind_review.tres`

更新：

- `scripts/run/route_state.gd`
  - 下一节点候选池末尾新增 `B003`，后续已扩展为 `B003` / `E005` 双候选。
  - `E005 转博申请` 现已作为分支事件接入，详细见 [034_transfer_application_event.md](034_transfer_application_event.md)。
- `scripts/battle/battle_state.gd`
  - 新增条件：`has_4_draft`、`has_2_reputation`、`has_2_reputation_or_4_draft`。
  - B003 信息区新增送审准备清单。
  - 阶段提示现在显示具体阶段名称，例如 `送审意见汇总`。
- `scripts/run/run_settlement.gd`
  - 新增 `blind_review_failed` 标题、描述和资源规则。
- `scripts/ui/battle_test_scene.gd`
  - 新增 `blind_review_failed` 结算强调色。
  - B003 胜利后显示毕业结局选择。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译和数据加载验证：

```text
res://scripts/battle/battle_state.gd=0
res://scripts/run/run_settlement.gd=0
res://scripts/run/route_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
boss_count=3
has_b003=true
b003_target=120
b003_intents=5
```

B003 提示和阶段检查验证：

```text
b003_hint=送审意见汇总：进度达到 70 时，需要至少 2 声望或 4 草稿。
b003_checklist=送审准备：声望 0/2，草稿 0/4，数据 0/2。
phase_triggered=true
progress_after_phase=82
```

路线接入验证：

```text
b002_options=b002_archive_materials,b002_replication_protocol,b002_cleanup_noise
selected_b002_reward=true
settlement_after_b002=false
options_after_b002=B003,E005
route_total_after_b002=8
selected_b003=true
current_boss=盲审专家
b003_options=b003_outstanding_graduation,b003_standard_graduation,b003_narrow_graduation
selected_b003_ending=true
settlement_after_b003=true
settlement_outcome=outstanding_graduation / master_graduated / narrow_graduation
final_route_ids=N001,N002,E004,N003,N004,B001,B002,B003
```

B003 失败结算验证：

```text
failure_title=盲审未过
failure_outcome=blind_review_failed
failure_resources={ experience_lessons: 6, methodology_notes: 2, psychological_resilience: 1, paper_fragments: 3, black_history_archive: 1 }
```

## 结果说明

- `B003 盲审专家` 已能作为第三个 Boss 出现在 `B002` 后。
- B002 通过后会继续路线，不再直接阶段结算。
- B003 有独立意图循环、阶段检查、可读性提示和失败结算。
- 不转博的硕士毕业线已经可以从 `B001` 跑到 `B003`，并进入毕业结局选择。

## 下一步

1. `E005 转博申请` 已完成首版接入，见 [034_transfer_application_event.md](034_transfer_application_event.md)。
2. 后续再评估是否实现“论证护盾”底层机制。
