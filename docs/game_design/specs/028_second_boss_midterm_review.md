# 第二个 Boss：中期考核 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [002_mvp_boss_set.md](002_mvp_boss_set.md)
- [013_run_settlement.md](013_run_settlement.md)
- [023_first_boss_node.md](023_first_boss_node.md)
- [027_boss_reward_visuals.md](027_boss_reward_visuals.md)
- [029_b002_material_checklist.md](029_b002_material_checklist.md)
- [030_b002_reward_pool.md](030_b002_reward_pool.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [032_third_boss_blind_review.md](032_third_boss_blind_review.md)
- [033_b003_graduation_endings.md](033_b003_graduation_endings.md)
- [034_transfer_application_event.md](034_transfer_application_event.md)
- [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md)

## 目标

把路线从 `B001 开题报告` 继续推进到第二个 Boss：`B002 中期考核`。

首版重点：

- 让研二阶段有明确 Boss 节点。
- 用数据、草稿和声望检查强化构筑方向。
- B002 的“材料清单”累计追踪已完成，见 [029_b002_material_checklist.md](029_b002_material_checklist.md)。
- 失败时进入专属坏结局 `中期预警`。
- 让 Boss 奖励面板能根据当前 Boss 显示不同标题和奖励文案。

## 路线接入

当前路线末段为：

```text
N004 截稿临近 -> B001 开题报告 -> B002 中期考核 -> B003 盲审专家
```

完成 `B001` 并选择 Boss 奖励后，不再立刻进入阶段结算，而是出现唯一下一节点：

```text
B002 中期考核
```

完成 `B002` 并选择 Boss 奖励后，会出现下一节点候选：

```text
B003 盲审专家 / 转博申请
```

选择 `B003` 会进入硕士毕业线；选择 `转博申请` 会进入 E005 分支事件。B003 接入记录见 [032_third_boss_blind_review.md](032_third_boss_blind_review.md)，毕业结局见 [033_b003_graduation_endings.md](033_b003_graduation_endings.md)，转博分支见 [034_transfer_application_event.md](034_transfer_application_event.md)。

## B002 中期考核

| 字段 | 内容 |
| --- | --- |
| ID | `B002` |
| 名称 | 中期考核 |
| 阶段 | 研二 Boss |
| 目标进度 | 95 |
| 开局负面 | 将 1 张 `S005 恍惚` 加入弃牌堆和牌组 |
| 阶段检查 | 进度达到 50 时触发一次“专家组建议”检查 |
| 失败结算 | `midterm_warning` / 中期预警 |

## 意图循环

| 回合 | 意图 | 首版效果 |
| --- | --- | --- |
| 1 | 汇报进展 | 造成 8 压力 |
| 2 | 数据真实性检查 | 若有数据，消耗 1 数据并获得 12 进度；否则加入 1 张 `S003 不可复现` |
| 3 | 时间表追问 | 造成 10 压力；若没有 2 草稿，加入 1 张 `S001 拖延` |
| 4 | 横向比较 | 造成 6 压力，加入 1 张 `S002 焦虑` |
| 5 | 阶段材料抽查 | 若本战累计获得过 2 数据和 3 草稿，获得 1 声望；否则加入 1 张 `S001 拖延` |

## 阶段检查

当进度达到 50 时触发一次“专家组建议”：

- 若本战累计获得过 2 数据或 3 草稿，获得 1 声望和 8 进度。
- 否则加入 1 张 `S002 焦虑`，并使目标进度 +8。

设计意图：

- 数据和草稿的本战累计获得量都能帮助通过中期。
- 只堆进度也能推进，但会吃到更多负面和更高目标。
- `做实验`、`样本制备`、`复现实验` 这类实验/数据牌在 B002 中更有价值。
- 数据真实性检查失败现在会加入 `S003 不可复现`，让实验噪音进入中期考核压力循环，见 [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md)。

## Boss 奖励

B002 已拥有专属 Boss 奖励池：

| 奖励 | 效果 |
| --- | --- |
| 归档材料清单 | 方法论笔记 +1，论文碎片 +1 |
| 建立复现实验流程 | 获得 1 张 `C013 复现实验` |
| 清理实验噪音 | 优先移除 `S005 恍惚`、`S002 焦虑` 或 `S001 拖延` |

## 中期预警

如果在 `B002` 中精力归零，结算为：

```text
outcome_id = midterm_warning
title = 中期预警
```

额外资源：

- 经验教训 +4。
- 方法论笔记 +2。
- 心理韧性 +1。
- 黑历史档案 +1。
- 若 Boss 进度达到目标一半及以上，论文碎片 +1。

## 实现内容

新增：

- `data/bosses/b002_midterm_review.tres`

更新：

- `scripts/run/route_state.gd`
  - 下一节点候选池末尾新增 `B002`。
- `scripts/battle/battle_state.gd`
  - 新增条件：`has_3_draft`、`has_2_data_and_3_draft`、`has_2_data_or_3_draft`。
  - Boss 阶段提示改为根据 `phase_event_id` 和 `phase_condition` 格式化。
  - 后续已加入本战累计材料清单条件，见 [029_b002_material_checklist.md](029_b002_material_checklist.md)。
- `scripts/run/run_settlement.gd`
  - 新增 `midterm_warning` 标题、描述和资源规则。
- `scripts/ui/battle_test_scene.gd`
  - Boss 失败结算改为读取 `boss_definition.failure_result`。
  - Boss 奖励面板根据当前 Boss 显示不同标题和奖励文案。
  - `midterm_warning` 结算拥有独立强调色。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
res://scripts/battle/battle_state.gd=0
res://scripts/run/run_settlement.gd=0
res://scripts/run/route_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

B002 数据与阶段检查验证：

```text
boss_count=3
has_b002=true
b002_name=中期考核
b002_target=95
b002_intents=5
b002_start_status=true
b002_intent_start=汇报进展：造成 8 压力
b002_readability=当前意图：汇报进展：造成 8 压力
专家组建议：进度达到 50 时，需要本战累计至少 2 数据或 3 草稿。
材料清单：本战累计数据 0/2，草稿 0/3。
b002_phase_near=专家组建议临近：还差 6 进度，准备本战累计至少 2 数据或 3 草稿。
b002_phase_triggered=true
b002_reputation_after_phase=1
b002_progress_after_phase=63
```

路线接入验证：

```text
b001_reward_title=开题报告通过
b001_reward_selected=true
settlement_after_b001=false
options_after_b001=B002
selected_b002=true
current_boss=中期考核
b002_is_boss=true
b002_target=95
b002_start_status=true
b002_reward_title=中期考核通过
b002_reward_buttons=3
b002_reward_selected=true
b002_reward_result=归档材料清单：方法论笔记 +1，论文碎片 +1。
settlement_after_b002=false
options_after_b002=B003,E005
route_total_after_b002=8
```

B002 失败结算验证：

```text
failure_visible=true
failure_outcome=midterm_warning
failure_title=中期预警
failure_resources=局外资源：经验教训 +17 | 方法论笔记 +8 | 心理韧性 +1 | 黑历史档案 +1
failure_next_available=false
```

## 结果说明

- `B002 中期考核` 已能作为第二个 Boss 出现在 `B001` 后。
- B001 与 B002 通过后都会继续路线，不再直接阶段结算。
- B002 有独立意图循环、阶段检查和失败结算。
- Boss 奖励面板会根据 B001/B002 显示不同标题和奖励文案。

## 下一步

1. B002 专属奖励池已完成，见 [030_b002_reward_pool.md](030_b002_reward_pool.md)。
2. B002 后转博/不转博分支锚点已记录，见 [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)。
3. `B003 盲审专家` 已完成首版实现，见 [032_third_boss_blind_review.md](032_third_boss_blind_review.md)。
4. `E005 转博申请` 已完成首版接入，见 [034_transfer_application_event.md](034_transfer_application_event.md)。
