# MVP Boss 规格 v0.1

状态：部分落地，`B001`、`B002`、`B003` 与转博线 `B004` 到 `B008` 已接入 Godot 路线

创建日期：2026-05-26

关联文档：

- [001_mvp_card_set.md](001_mvp_card_set.md)
- [../01_core_loop.md](../01_core_loop.md)
- [023_first_boss_node.md](023_first_boss_node.md)
- [025_proposal_delay_settlement.md](025_proposal_delay_settlement.md)
- [027_boss_reward_visuals.md](027_boss_reward_visuals.md)
- [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)
- [029_b002_material_checklist.md](029_b002_material_checklist.md)
- [030_b002_reward_pool.md](030_b002_reward_pool.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [032_third_boss_blind_review.md](032_third_boss_blind_review.md)
- [033_b003_graduation_endings.md](033_b003_graduation_endings.md)
- [034_transfer_application_event.md](034_transfer_application_event.md)
- [035_doctoral_route_entry.md](035_doctoral_route_entry.md)
- [036_b004_doctoral_qualification.md](036_b004_doctoral_qualification.md)
- [037_doctor2_project_pressure.md](037_doctor2_project_pressure.md)
- [038_doctor2_funding_window.md](038_doctor2_funding_window.md)
- [039_b005_project_midterm.md](039_b005_project_midterm.md)
- [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)
- [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)
- [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)
- [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)
- [044_b007_graduation_endings.md](044_b007_graduation_endings.md)
- [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)
- [046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md)
- [047_doctor4_revision_route.md](047_doctor4_revision_route.md)
- [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md)

## 通用 Boss 规则

Boss 不使用传统生命值，使用“阶段目标进度”。玩家通过卡牌获得进度，达到目标后通过考核。

Boss 每回合执行一个意图。意图分为：

- 压力：造成压力伤害。
- 干扰：加入负面牌、增加费用、移除资源。
- 检查：根据玩家资源触发不同结果。
- 阶段转换：目标进度过半或特定回合触发。

## B001 开题报告

阶段：研一 Boss

目标进度：70

设计目的：检查玩家是否理解文献、方向和基础表达。难度低于后续 Boss，但会第一次展示“资源检查”机制。

### 初始规则

- 战斗开始时，将 1 张“自我怀疑”加入弃牌堆。
- 玩家每拥有 1 声望，开局获得 2 进度，最多 6。

### 意图循环

| 回合 | 意图 | 效果 |
| --- | --- | --- |
| 1 | 研究意义追问 | 造成 7 压力；若玩家没有灵感，加入 1 张“自我怀疑” |
| 2 | 文献基础检查 | 若玩家有至少 2 灵感，玩家获得 1 草稿；否则加入 1 张“信息过载” |
| 3 | 方向可行性质疑 | 造成 9 压力，下一张论文牌费用 +1 |
| 4 | 导师补充问题 | 加入 1 张“拖延”，Boss 目标进度 +5 |
| 循环 | 重复 1-4 | 直到胜利或失败 |

### 阶段转换

当玩家累计进度达到 35 时，触发“确定题目”：

- 若玩家有 2 草稿或 2 数据，获得 10 进度。
- 否则加入 1 张“延期警告”。

### 胜利奖励

选择一项：

- 升级 1 张文献牌。
- 获得 1 张方向相关奖励牌。
- 移除 1 张“自我怀疑”或“信息过载”。

### 失败结算

结局不是直接游戏结束，而是“开题延期”：

- 获得额外经验教训、方法论笔记、心理韧性和黑历史档案。
- 若 Boss 进度达到目标一半及以上，额外获得 1 论文碎片。
- 进入局外结算，下一局继续带入资源成长。

## B002 中期考核

阶段：研二 Boss

目标进度：95

设计目的：推动玩家把数据、草稿和进度结合起来，避免只靠单一伤害牌通过。

### 初始规则

- 首版实现中，战斗开始时将 1 张 `S005 恍惚` 加入弃牌堆和牌组。
- “材料清单”使用本场战斗累计获得量：2 数据和 3 草稿。

### 意图循环

| 回合 | 意图 | 效果 |
| --- | --- | --- |
| 1 | 汇报进展 | 造成 8 压力 |
| 2 | 数据真实性检查 | 若玩家有数据，消耗 1 数据并获得 12 进度；否则加入 1 张 `S003 不可复现` |
| 3 | 时间表追问 | 造成 10 压力；若玩家草稿少于 2，加入 1 张“拖延” |
| 4 | 横向比较 | 造成 6 压力，加入 1 张“焦虑” |
| 5 | 阶段材料抽查 | 若本战累计获得过 2 数据和 3 草稿，获得 1 声望；否则加入 1 张“拖延” |
| 循环 | 重复 1-5 | 直到胜利或失败 |

### 阶段转换

当玩家累计进度达到 50 时，触发“专家组建议”：

- 若本战累计获得过 2 数据或 3 草稿，获得 1 声望和 8 进度。
- 否则加入 1 张“焦虑”，Boss 目标进度 +8。

### 胜利奖励

B002 专属奖励三选一：

- 归档材料清单：方法论笔记 +1，论文碎片 +1。
- 建立复现实验流程：获得 1 张 `C013 复现实验`。
- 清理实验噪音：移除 1 张“恍惚”“焦虑”或“拖延”。

### 失败结算

触发“中期预警”：

- 额外获得经验教训、方法论笔记、心理韧性和黑历史档案。
- 若 Boss 进度达到目标一半及以上，额外获得 1 论文碎片。

## B003 盲审专家

阶段：研三 Boss

目标进度：120

设计目的：作为 MVP 最终 Boss，要求玩家把数据、草稿、论文牌、声望和负面管理整合起来。

### 初始规则

- 首版实现中，战斗开始时将 1 张 `S004 信息过载` 加入弃牌堆和牌组。
- “论证护盾”暂不接入底层机制，先用高目标进度、逐条反驳和阶段检查表达盲审压力。
- 后续可追加：每回合前 6 点进度无效；玩家每有 1 声望，论证护盾降低 1，最低为 2；使用论文牌后，本回合论证护盾失效。

### 意图循环

| 回合 | 意图 | 效果 |
| --- | --- | --- |
| 1 | 创新性质疑 | 造成 10 压力；若玩家没有灵感，加入 1 张“自我怀疑” |
| 2 | 数据充分性审查 | 若玩家有 2 数据，消耗 1 数据并获得 15 进度；否则加入 1 张“信息过载” |
| 3 | 格式与规范 | 加入 1 张“信息过载”，造成 6 压力 |
| 4 | 逐条反驳 | 造成 12 压力；下一次获得进度 -6 |
| 5 | 大修意见 | 加入 1 张“焦虑”；Boss 目标进度 +8 |
| 循环 | 重复 1-5 | 直到胜利或失败 |

### 阶段转换

当玩家累计进度达到 70 时，触发“送审意见汇总”：

- 若玩家声望至少 2 或草稿至少 4，获得 12 进度。
- 若以上都不满足，加入 1 张“拖延”和 1 张“焦虑”。

### 胜利奖励

B003 胜利后进入毕业结局选择：

- 优秀毕业：精力至少 20，且声望至少 2。
- 顺利毕业：精力至少 10，且声望至少 1 或草稿至少 4。
- 擦线毕业：始终可选，局外获得更多经验教训和心理韧性。

### 失败结算

触发“盲审未过”：

- 获得额外经验教训、方法论笔记、心理韧性、论文碎片和黑历史档案。
- 解锁局外能力候选：`审稿人雷达`。
- 下一局事件池加入“重投经验分享”。

## B002 后路线分支锚点

`B002 中期考核` 后续会成为路线分歧点：

- 不转博：进入 `B003 盲审专家`，完成硕士毕业线。
- 申请转博：满足条件后进入博士追加路线，后续包含博一、博二、博三阶段。

当前已先实现 `B003` 并跑通硕士毕业线，转博条件和追加路线记录在 [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)。

## Boss 纸面测试关注点

- 开题报告是否能在 5 到 8 回合内结束。
- 中期考核是否真的鼓励数据和草稿，而不是只堆进度。
- 盲审专家的论证护盾是否让论文牌有价值。
- 失败结算是否让玩家觉得“还能再来一局”。

## Godot 实现进度

- `B001 开题报告` 已完成首版实现，并接入 `N004` 后。
- `B001` 的意图提示、阶段检查提示和 Boss 专属胜利奖励已完成。
- `B001 开题延期` 失败结算已完成。
- `B001` Boss 胜利奖励已拥有专属面板和按钮样式。
- `B002 中期考核` 已完成首版实现，并接入 `B001` 后的路线终点。
- `B002` 材料清单累计追踪已完成。
- `B002` 的数据真实性检查失败现在会加入 `S003 不可复现`，见 [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md)。
- `B002` 专属奖励池已完成。
- `B003 盲审专家` 已完成首版实现，并接入 `B002` 后的不转博硕士毕业线。
- `B003` 毕业结局选择已完成。
- `B002` 后转博/不转博分支已完成首版接入，`E005 转博申请` 成功后可进入博士线，并已推进到 `B008 补答辩`。
- 博士线普通奖励池已完成，让 N005/N006/N007 拥有专属博士线卡。
- B007 博士毕业结局选择已完成，提供优秀博士毕业、博士毕业和延毕后毕业。
- B004 到 B006 博士 Boss 专属奖励池已完成；B007 保持博士毕业结局选择。
- E007 博四返修会已完成，B007 精力归零后先进入返修事件。
- 博四短路线 `E007 -> N008 -> B008` 已完成，B008 胜利进入 `延毕后毕业`，失败进入 `补答辩再延期`。
- 详细实现和验证记录见 [023_first_boss_node.md](023_first_boss_node.md)、[024_boss_readability_and_rewards.md](024_boss_readability_and_rewards.md)、[025_proposal_delay_settlement.md](025_proposal_delay_settlement.md)、[027_boss_reward_visuals.md](027_boss_reward_visuals.md)、[028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)、[029_b002_material_checklist.md](029_b002_material_checklist.md)、[030_b002_reward_pool.md](030_b002_reward_pool.md)、[031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)、[032_third_boss_blind_review.md](032_third_boss_blind_review.md)、[033_b003_graduation_endings.md](033_b003_graduation_endings.md)、[034_transfer_application_event.md](034_transfer_application_event.md)、[035_doctoral_route_entry.md](035_doctoral_route_entry.md)、[036_b004_doctoral_qualification.md](036_b004_doctoral_qualification.md)、[037_doctor2_project_pressure.md](037_doctor2_project_pressure.md)、[038_doctor2_funding_window.md](038_doctor2_funding_window.md)、[039_b005_project_midterm.md](039_b005_project_midterm.md)、[040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)、[041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)、[042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)、[043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)、[044_b007_graduation_endings.md](044_b007_graduation_endings.md)、[045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)、[046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md) 与 [047_doctor4_revision_route.md](047_doctor4_revision_route.md)。
