# 阶段结算与坏结局正反馈规格 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [03_meta_progression_and_legacy.md](../03_meta_progression_and_legacy.md)
- [011_node_loop.md](011_node_loop.md)
- [012_route_state_and_encounter_variants.md](012_route_state_and_encounter_variants.md)
- [019_event_nodes_in_route.md](019_event_nodes_in_route.md)
- [023_first_boss_node.md](023_first_boss_node.md)
- [025_proposal_delay_settlement.md](025_proposal_delay_settlement.md)
- [026_settlement_visual_hierarchy.md](026_settlement_visual_hierarchy.md)
- [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)
- [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)
- [044_b007_graduation_endings.md](044_b007_graduation_endings.md)
- [046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md)
- [047_doctor4_revision_route.md](047_doctor4_revision_route.md)
- [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md)

## 目标

把“每一局都有价值”的设计落到原型里。即使玩家没有完成路线、因为精力归零提前结束，也会获得可见的局外资源，为下一次尝试提供正反馈。

## 结算触发

| 触发 | outcome_id | 标题 | 说明 |
| --- | --- | --- | --- |
| 完成当前 MVP 路线并选择最后一次奖励 | `route_completed` | 阶段通过 | 玩家撑过本段研究路线，构筑成长和方法经验被记录 |
| `B003 盲审专家` 胜利后选择优秀毕业 | `outstanding_graduation` | 优秀毕业 | 高质量毕业结局，奖励偏向论文成果和方法沉淀 |
| `B003 盲审专家` 胜利后选择顺利毕业 | `master_graduated` | 顺利毕业 | 稳定毕业结局，奖励均衡 |
| `B003 盲审专家` 胜利后选择擦线毕业 | `narrow_graduation` | 擦线毕业 | 保底毕业结局，奖励偏向复盘和韧性 |
| `B007 博士答辩` 胜利后选择优秀博士毕业 | `outstanding_doctoral_graduation` | 优秀博士毕业 | 高质量博士毕业结局，奖励最高 |
| `B007 博士答辩` 胜利后选择博士毕业 | `doctoral_graduated` | 博士毕业 | 标准博士线通关结局，奖励偏向论文成果、方法沉淀和心理韧性 |
| `B007 博士答辩` 胜利后选择延毕后毕业 | `delayed_doctoral_graduation` | 延毕后毕业 | 保底博士毕业结局，奖励偏向延毕复盘和心理韧性 |
| `B008 补答辩` 胜利后选择任一收束方式 | `delayed_doctoral_graduation` | 延毕后毕业 | 博四短路线通关结局，奖励叠加返修选择 |
| `E005 转博申请` 提交成功但博士线入口缺失 | `transfer_admitted` | 转博资格确认 | 转博路线兜底结算，奖励偏向方法、论文和后续博士线 |
| 精力降到 0 | `burnout` | 精力耗尽 | 坏结局仍产生复盘价值，奖励偏向心理韧性和黑历史档案 |
| `B001 开题报告` 中精力降到 0 | `proposal_delayed` | 开题延期 | Boss 坏结局，奖励偏向复盘、方法调整和韧性 |
| `B002 中期考核` 中精力降到 0 | `midterm_warning` | 中期预警 | Boss 坏结局，奖励偏向材料复盘和方法调整 |
| `B003 盲审专家` 中精力降到 0 | `blind_review_failed` | 盲审未过 | Boss 坏结局，奖励偏向论文返修、方法复盘和韧性 |
| `B004 博士资格考核` 中精力降到 0 | `qualification_failed` | 博士资格考核未过 | Boss 坏结局，奖励偏向理论根基、论文管线和长期复盘 |
| `B005 项目中期检查` 中精力降到 0 | `project_midterm_failed` | 项目中期检查未过 | Boss 坏结局，奖励偏向项目管理、论文管线和长期复盘 |
| `B006 博士预答辩` 中精力降到 0 | `predefense_failed` | 博士预答辩未过 | Boss 坏结局，奖励偏向论文主线、方法叙事、答辩风险和长期复盘 |
| `B007 博士答辩` 中精力降到 0，且博四短路线缺失 | `doctoral_defense_delayed` | 博士答辩延期 | 博四/延毕入口兜底坏结局 |
| `B008 补答辩` 中精力降到 0 | `supplementary_defense_failed` | 补答辩再延期 | 更深一层的延毕坏结局，奖励偏向韧性、返修矩阵和黑历史档案 |

## 局外资源

首版结算只显示资源，不写入存档。资源命名沿用局外成长文档：

| 资源 | 用途方向 |
| --- | --- |
| 经验教训 | 解锁通用卡、事件、开局选项 |
| 方法论笔记 | 解锁研究方向强化 |
| 心理韧性 | 解锁调适牌和保护能力 |
| 论文碎片 | 解锁论文牌和审稿相关遗物 |
| 黑历史档案 | 解锁坏结局事件线和风险提示 |

## 计算规则

基础输入：

- `completed_nodes`：已完成节点数。
- `deck_growth`：当前牌组张数相对初始牌组的增长量。
- `vitality`：结算时精力。

资源计算：

- `经验教训 = max(1, completed_nodes * 2 + deck_growth)`
- `方法论笔记 = completed_nodes + floor(deck_growth / 2)`
- `route_completed` 额外获得：经验教训 +2，方法论笔记 +2，论文碎片 +1。
- 如果 `route_completed` 发生在 Boss 战后，额外获得方法论笔记 +2，论文碎片 +1。
- `outstanding_graduation` 额外获得：经验教训 +3，方法论笔记 +4，论文碎片 +4。
- `master_graduated` 额外获得：经验教训 +2，方法论笔记 +3，论文碎片 +3。
- `narrow_graduation` 额外获得：经验教训 +4，方法论笔记 +1，心理韧性 +1，论文碎片 +1。
- `outstanding_doctoral_graduation` 额外获得：经验教训 +6，方法论笔记 +8，心理韧性 +2，论文碎片 +8。
- `doctoral_graduated` 额外获得：经验教训 +5，方法论笔记 +6，心理韧性 +2，论文碎片 +6。
- `delayed_doctoral_graduation` 额外获得：经验教训 +8，方法论笔记 +4，心理韧性 +3，论文碎片 +4。
- `transfer_admitted` 额外获得：经验教训 +2，方法论笔记 +3，论文碎片 +2。
- `burnout` 额外获得：经验教训 +1，心理韧性 +2，黑历史档案 +1。
- `proposal_delayed` 额外获得：经验教训 +3，方法论笔记 +1，心理韧性 +1，黑历史档案 +1；若 Boss 进度达到目标一半及以上，论文碎片 +1。
- `midterm_warning` 额外获得：经验教训 +4，方法论笔记 +2，心理韧性 +1，黑历史档案 +1；若 Boss 进度达到目标一半及以上，论文碎片 +1。
- `blind_review_failed` 额外获得：经验教训 +5，方法论笔记 +2，心理韧性 +1，论文碎片 +2，黑历史档案 +1；若 Boss 进度达到目标一半及以上，论文碎片 +1。
- `qualification_failed` 额外获得：经验教训 +6，方法论笔记 +3，心理韧性 +1，论文碎片 +2，黑历史档案 +1；若 Boss 进度达到目标一半及以上，论文碎片 +1。
- `project_midterm_failed` 额外获得：经验教训 +7，方法论笔记 +3，心理韧性 +1，论文碎片 +3，黑历史档案 +1；若 Boss 进度达到目标一半及以上，论文碎片 +1。
- `predefense_failed` 额外获得：经验教训 +8，方法论笔记 +4，心理韧性 +2，论文碎片 +4，黑历史档案 +1；若 Boss 进度达到目标一半及以上，论文碎片 +1。
- `doctoral_defense_delayed` 额外获得：经验教训 +10，方法论笔记 +5，心理韧性 +3，论文碎片 +5，黑历史档案 +1；若 Boss 进度达到目标一半及以上，论文碎片 +1。
- `supplementary_defense_failed` 额外获得：经验教训 +12，方法论笔记 +6，心理韧性 +4，论文碎片 +5，黑历史档案 +1；若 Boss 进度达到目标一半及以上，论文碎片 +1；局外解锁 `revision_matrix_seed`，见 [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md)。
- 若结算时精力大于 0 且不高于最大精力 35%，额外获得心理韧性 +1。
- 事件节点中获得的 `experience_lessons`、`methodology_notes`、`paper_fragments` 会并入阶段结算资源。

设计意图：

- 完成路线给更全面的成长。
- 坏结局不给强力数值补偿，但一定给“失败相关”的资源。
- 任何结算至少给 1 点经验教训。

## 实现内容

新增脚本：

- `scripts/run/run_settlement.gd`
  - `build(route, battle, reason)`：生成结算字典。
  - 输出 `outcome_id`、标题、描述、完成节点、牌组张数、精力、资源和 `summary_text`。
  - 将事件节点累计在 `BattleState` 里的局外资源并入最终结算。

更新：

- `scripts/run/route_state.gd`
  - 新增 `get_completed_node_count()`。
- `scripts/ui/battle_test_scene.gd`
  - 新增 `settlement` 状态。
  - 新增结算显示标签。
  - 新增 `get_settlement_visible()`、`get_settlement_outcome_id()`、`get_settlement_summary()`、`get_settlement_resource()` 供验证使用。
  - 精力归零时调用 `RunSettlement.build(..., "burnout")`。
  - `B001` 精力归零时调用 `RunSettlement.build(..., "proposal_delayed")`。
  - `B007` 精力归零时先进入 `E007 博四返修会`；后续进入 `N008 返修长夜` 和 `B008 补答辩`。
  - `B008` 胜利后调用 `RunSettlement.build(..., "delayed_doctoral_graduation")`。
  - `B008` 精力归零时调用 `RunSettlement.build(..., "supplementary_defense_failed")`。
  - 普通阶段终点选择奖励后调用 `RunSettlement.build(..., "route_completed")`。
  - `B007` 胜利奖励后根据结局按钮调用 `outstanding_doctoral_graduation`、`doctoral_graduated` 或 `delayed_doctoral_graduation`。
  - 结算后禁用继续战斗和下一节点入口。
  - 结算区域已拆成标题、说明、状态、资源和存档结果，见 [026_settlement_visual_hierarchy.md](026_settlement_visual_hierarchy.md)。

## 验证记录

以下验证记录来自事件节点接入前的 4 战斗固定路线；事件节点接入后的资源并入验证见 [019_event_nodes_in_route.md](019_event_nodes_in_route.md)。

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
reload_route_state.gd=0
reload_run_settlement.gd=0
reload_battle_state.gd=0
reload_battle_test_scene.gd=0
```

路线完成结算验证：

```text
success_visible=true
success_outcome=route_completed
success_completed=4
success_deck=19
success_lessons=14
success_methodology=8
success_paper=1
success_next_available=false
```

精力耗尽结算验证：

```text
burnout_visible=true
burnout_outcome=burnout
burnout_completed=0
burnout_deck=15
burnout_lessons=2
burnout_resilience=2
burnout_black_history=1
burnout_next_available=false
```

结果说明：

- 完成路线后能显示阶段通过结算，并给出局外资源。
- 坏结局同样能显示结算，并给出与失败相关的资源。
- 结算都会关闭下一节点入口，避免结算后继续推进路线。
- 当前只展示结算结果，尚未写入永久存档。
- `B001 开题延期` 已接入为 Boss 专属坏结局，见 [025_proposal_delay_settlement.md](025_proposal_delay_settlement.md)。
- `B002 中期预警` 和 `B003 盲审未过` 已接入，见 [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md) 与 [032_third_boss_blind_review.md](032_third_boss_blind_review.md)。
- `B003` 毕业结局选择已接入，见 [033_b003_graduation_endings.md](033_b003_graduation_endings.md)。
- `E005 转博申请` 已接入，成功提交后优先进入 `N005`；`transfer_admitted` 保留为兜底结算，见 [034_transfer_application_event.md](034_transfer_application_event.md) 与 [035_doctoral_route_entry.md](035_doctoral_route_entry.md)。
- `B004 博士资格考核未过` 已接入，见 [036_b004_doctoral_qualification.md](036_b004_doctoral_qualification.md)。
- `B005 项目中期检查未过` 已接入，见 [039_b005_project_midterm.md](039_b005_project_midterm.md)。
- `B006 博士预答辩未过` 已接入，见 [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)。
- `B007` 博士毕业结局选择和博四短路线已接入；B007 失败后会先进入 `E007 -> N008 -> B008`，见 [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)、[044_b007_graduation_endings.md](044_b007_graduation_endings.md)、[046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md) 与 [047_doctor4_revision_route.md](047_doctor4_revision_route.md)。

## 下一步

1. 局外资源存档层已完成，见 [014_meta_progression_save.md](014_meta_progression_save.md)。
2. 结算区域视觉层级已完成，见 [026_settlement_visual_hierarchy.md](026_settlement_visual_hierarchy.md)。
3. `self_care_seed` 已接到初始牌组，见 [015_first_meta_unlock_card.md](015_first_meta_unlock_card.md)。
