# B002 后转博分支锚点 v0.2

状态：首版分支、博士线入口、博二段落、博三入口和博三 Boss 已接入

创建日期：2026-05-27

关联文档：

- [002_mvp_boss_set.md](002_mvp_boss_set.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)
- [030_b002_reward_pool.md](030_b002_reward_pool.md)
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
- [081_transfer_branch_requirements.md](081_transfer_branch_requirements.md)

## 目标

把“研二 Boss 后可以选择转博”固定成后续路线设计的锚点，避免在接入 `B003 盲审专家` 后再返工路线结构。

当前阶段已经接入：

- `B003` 不转博硕士毕业线。
- `E005 转博申请` 分支事件，见 [034_transfer_application_event.md](034_transfer_application_event.md)。
- `E005` 详情面板中的转博资格进度，见 [081_transfer_branch_requirements.md](081_transfer_branch_requirements.md)。
- `N005 博一开题重构` 博士线入口，见 [035_doctoral_route_entry.md](035_doctoral_route_entry.md)。
- `B004 博士资格考核` 首个博士 Boss，见 [036_b004_doctoral_qualification.md](036_b004_doctoral_qualification.md)。
- `N006 项目推进压力` 博二入口，见 [037_doctor2_project_pressure.md](037_doctor2_project_pressure.md)。
- `E006 基金申请窗口` 博二资源取舍事件，见 [038_doctor2_funding_window.md](038_doctor2_funding_window.md)。
- `B005 项目中期检查` 博二 Boss，见 [039_b005_project_midterm.md](039_b005_project_midterm.md)。
- `N007 预答辩筹备` 博三入口，见 [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)。
- `B006 博士预答辩` 博三 Boss，见 [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)。
- `B007 博士答辩` 当前博士线终局 Boss，见 [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)。
- `E007 博四返修会` 答辩延期后的返修事件，见 [046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md)。
- `N008 返修长夜` 与 `B008 补答辩` 组成博四短路线，见 [047_doctor4_revision_route.md](047_doctor4_revision_route.md)。

## 路线决策

当前实现阶段：

```text
B001 开题报告 -> B002 中期考核
  -> 不转博：B003 盲审专家 -> 毕业结算
  -> 转博：E005 转博申请 -> N005 博一开题重构 -> B004 博士资格考核 -> N006 项目推进压力 -> E006 基金申请窗口 -> B005 项目中期检查 -> N007 预答辩筹备 -> B006 博士预答辩 -> B007 博士答辩 -> 博士毕业 / E007 博四返修会 -> N008 返修长夜 -> B008 补答辩 -> 延毕后毕业 / 补答辩再延期
```

后续博士线展开后：

```text
E005 转博申请 -> N005 博一开题重构 -> B004 博士资格考核 -> N006 项目推进压力 -> E006 基金申请窗口 -> B005 项目中期检查 -> N007 预答辩筹备 -> B006 博士预答辩 -> B007 博士答辩 -> 博士毕业 / E007 博四返修会 -> N008 返修长夜 -> B008 补答辩 -> 延毕后毕业 / 补答辩再延期
```

## 分支语义

| 分支 | 玩家表达 | 路线长度 | 设计定位 |
| --- | --- | --- | --- |
| 不转博 | 继续完成硕士毕业 | 短 | 更稳定，目标清晰，尽快进入毕业 Boss |
| 申请转博 | 扩展为博士路线 | 长 | 风险更高，构筑容量更大，奖励和坏结局资源更多 |

不转博不是“差选择”，而是稳定通关路线。转博也不是纯增强，而是用更多节点换更高上限和更复杂压力。

## 转博触发条件候选

首版接入时可以先使用宽松条件，只要能让玩家理解“这是争取来的机会”：

- 已通过 `B002 中期考核`。
- 本局声望至少 2。
- `B002` 材料清单曾达标，或拥有至少 2 数据和 3 草稿的阶段记录。

后续可以加入更有叙事味的条件：

- 事件中获得过 `导师支持`。
- 局外资源 `方法论笔记` 达到一定数量。
- 曾选择 `建立复现实验流程` 或拥有实验/论文方向关键牌。
- 伦理风险、心理压力或延期标记不能过高。

当前原型先显示 `E005 转博申请`，在事件详情和提交选项中显示锁定状态与缺失条件，见 [081_transfer_branch_requirements.md](081_transfer_branch_requirements.md)。后续正式版可以再把“E005 是否出现”改为条件触发，并在未触发时保留不转博硕士线。

## 博士路线草案

转博后的学历等级仍沿用用户提出的上限：

```text
博一 -> 博二 -> 博三 -> 博四及以后属于延毕状态
```

首版博士路线可以比硕士路线多 2 到 3 个阶段：

| 阶段 | 节点草案 | 主题 |
| --- | --- | --- |
| 博一 | 博士资格考核 | 研究方向重置、资格考试、课题规模变大 |
| 博二 | 项目推进 / 基金压力 | 长线实验、横向项目、导师资源与合作关系 |
| 博三 | 博士预答辩 / 博士答辩 | 高目标进度、多轮修改、毕业与延毕判断 |
| 博四+ | 延毕状态 | 不是常规等级上限，而是失败或拖延后的特殊路线 |

## 正反馈原则

无论玩家选择哪条路线，都要保留正反馈：

- 不转博并毕业：获得稳定的论文碎片、经验教训和毕业相关局外能力。
- 申请转博成功：获得博士路线专属解锁、构筑容量或高阶牌池入口。
- 申请转博失败：不直接清空努力，获得申请材料经验、导师沟通经验或方法论笔记。
- 博士路线中失败或延毕：结算资源更偏向长期成长，例如心理韧性、黑历史档案和复盘能力。

## 实现契约

当前已经把 `B003` 与 `E005` 都加入 `RouteState.DEFAULT_CHOICE_COLUMNS` 的 B002 后候选列。

博士线入口 `N005` 不直接加入默认候选列，而是由 `E005` 成功提交后通过 `advance_to_node()` 追加。这样可以避免不转博路线误读博士线候选，也能在节点缺失时回退到 `transfer_admitted` 结算。

接入顺序：

1. `B003` 已完成，B002 后的不转博硕士毕业线已跑通。
2. `E005 转博申请` 已完成，B002 后的候选已扩展为 `B003` 与 `E005`。
3. `N005 博一开题重构` 已完成，转博成功后可以进入博士线入口。
4. `B004 博士资格考核` 已完成，N005 奖励选择后会进入首个博士 Boss。
5. `N006 项目推进压力` 已完成，B004 奖励选择后会进入博二入口。
6. `E006 基金申请窗口` 已完成，N006 奖励选择后会进入博二资源取舍事件。
7. `B005 项目中期检查` 已完成，E006 事件选择后会进入博二 Boss。
8. `N007 预答辩筹备` 已完成，B005 奖励选择后会进入博三入口。
9. `B006 博士预答辩` 已完成，N007 奖励选择后会进入博三 Boss。
10. `B007 博士答辩` 已完成，B006 奖励选择后会进入当前博士线终局。
11. `E007 博四返修会`、`N008 返修长夜` 与 `B008 补答辩` 已完成，B007 精力归零后会进入博四返修短路线，再收束到延毕后毕业或补答辩再延期。

条件过滤可以放在 UI 层或路线层，但必须满足：

- 条件不足时不出现可点击的转博按钮。
- 条件满足时，B002 奖励选择后能看到“不转博”和“申请转博”的明确差异。
- 任一分支都不能造成路线条、结算或下一节点按钮卡死。

## 验收标准

当前阶段：

- B002 胜利奖励选择后出现 `B003 盲审专家` 和 `E005 转博申请`。
- B003 胜利奖励选择后正常进入阶段结算。
- E005 条件不足时能回到 B003，条件满足时进入 `N005 博一开题重构`。
- N005 完成后进入 `B004 博士资格考核`。
- B004 胜利后进入 `N006 项目推进压力`，失败后进入 `博士资格考核未过`。
- N006 完成后进入 `E006 基金申请窗口`。
- E006 选择事件选项后进入 `B005 项目中期检查`。
- B005 胜利后进入 `N007 预答辩筹备`，失败后进入 `项目中期检查未过`。
- N007 完成后进入 `B006 博士预答辩`。
- B006 胜利后进入 `B007 博士答辩`，失败后进入 `博士预答辩未过`。
- B007 胜利后进入 `博士毕业结局选择`，失败后进入 `E007 博四返修会`，选择返修方向后进入 `N008 返修长夜`，再进入 `B008 补答辩`。
- B008 胜利后进入 `补答辩结局选择`，失败后进入 `补答辩再延期`。

接入转博分支后：

- 条件不足：只显示 `B003` 或显示不可点的锁定提示。
- 条件满足：显示 `不转博` 与 `申请转博` 两个方向。
- 选择不转博进入 `B003`。
- 选择申请转博进入博士追加路线。

## 下一步

1. E005 转博申请已完成，见 [034_transfer_application_event.md](034_transfer_application_event.md)。
2. N005 博一开题重构已完成，见 [035_doctoral_route_entry.md](035_doctoral_route_entry.md)。
3. B004 博士资格考核已完成，见 [036_b004_doctoral_qualification.md](036_b004_doctoral_qualification.md)。
4. N006 项目推进压力已完成，见 [037_doctor2_project_pressure.md](037_doctor2_project_pressure.md)。
5. E006 基金申请窗口已完成，见 [038_doctor2_funding_window.md](038_doctor2_funding_window.md)。
6. B005 项目中期检查已完成，见 [039_b005_project_midterm.md](039_b005_project_midterm.md)。
7. N007 预答辩筹备已完成，见 [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md)。
8. B006 博士预答辩已完成，见 [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md)。
9. 博士线普通奖励池已完成，见 [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)。
10. B007 博士答辩已完成，见 [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md)。
11. B007 博士毕业结局分层已完成，见 [044_b007_graduation_endings.md](044_b007_graduation_endings.md)。
12. E007 博四返修会已完成，见 [046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md)。
13. 博四短路线 `E007 -> N008 -> B008` 已完成，见 [047_doctor4_revision_route.md](047_doctor4_revision_route.md)。
