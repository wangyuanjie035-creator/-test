# 123 标签驱动的候选池选择器

## 目标

承接 [122_campus_tag_driven_generation_draft.md](122_campus_tag_driven_generation_draft.md)，实现一层候选池选择器预览：根据阶段目标点数、required tags、focus tags 和 seed，从候选交互池中稳定选出目标数量的校园点位。

本步不替换当前固定地图，不改变 `_spawn_interactables()` 的输入，也不影响移动、点位触发、资源、战斗和剧情推进。当前固定阶段池仍照常运行；选择器用于预览、审查和后续接入更大的随机候选池。

## 选择规则

- 当前候选池先使用阶段自身的 `interactions`。
- 目标数量读取 `generation_target_interaction_count`，当前为 12。
- 选择器先覆盖 `generation_required_tags`，避免缺少关键体验。
- 之后按候选的 required/focus 标签命中、交互类型权重和 seed tie-breaker 填满目标数量。
- 选择器使用阶段 seed 和候选 ID 做稳定排序，相同 seed 下结果稳定。
- 当前候选池大小等于目标数量时，选择器会选出全部固定点位，但顺序会按得分和 seed 排列。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `get_stage_generation_candidate_pool_summary()`。
  - 新增 `get_stage_generation_selected_interaction_ids_summary()`。
  - 新增 `get_stage_generation_selected_tag_mix_summary()`。
  - 新增 `get_stage_generation_selection_missing_tag_summary()`。
  - 新增 `get_stage_generation_selection_audit_summary()`。
  - 新增 `_get_interaction_definition_content_tags()`，让未实例化的 Resource 候选也能参与标签判断。
  - 新增 `_select_generation_candidate_definitions()` 和相关评分/稳定排序函数。
  - `_infer_content_tags()` 拆分出 `_infer_content_tags_from_fields()`，运行时点位和 Resource 候选共用同一套推断逻辑。

## 验证记录

脚本加载：

```text
campus_overworld_scene=0
```

六阶段选择预览：

```text
master1=pool=12,target=12,selected=12,missing=0,focus_hits=7/7
master2=pool=12,target=12,selected=12,missing=0,focus_hits=7/7
doctor1=pool=12,target=12,selected=12,missing=0,focus_hits=7/7
doctor2=pool=12,target=12,selected=12,missing=0,focus_hits=6/6
doctor3=pool=12,target=12,selected=12,missing=0,focus_hits=6/6
doctor4=pool=12,target=12,selected=12,missing=0,focus_hits=6/6
```

研二选择示例：

```text
pool=12,target=12,seed=73700
selection=pool=12,target=12,selected=12,missing=0,focus_hits=7/7
ids=midterm_room,archived_draft_stack,review_checklist,transfer_office,blind_review_room,paper_fragments_pinboard,submission_rehearsal,replication_data_pack,data_cleaning_night,replication_alarm,preprint_discussion,review_reputation_note
mix=数据=3、草稿=2、写作=7、导师=2、委员会=2、设备=2、论文碎片=2
```

临时缩小目标数的稳定性验证：

```text
reduced_seed1_stable=true
reduced_seed1_audit=pool=12,target=8,selected=8,missing=0,focus_hits=6/7
```

## 手测重点

1. 当前实际校园地图仍应保持每阶段 12 个固定点位。
2. 研二仍应优先指向 `B002 中期考核`，补给建议仍应指向 `复现数据包、归档草稿`。
3. 点位图、任务视图、靠近信息卡和返回摘要不应因选择器预览而改变行为。
4. 后续扩展候选池时，选择审查应能暴露 selected 数量、missing tags 和 focus 命中情况。
5. 相同 seed 下选择结果应稳定，方便复现和调试。

## 下一步

1. 已完成“交互候选库扩容”，见 [124_campus_candidate_pool_expansion.md](124_campus_candidate_pool_expansion.md)。
2. 可以继续做“候选池接入开关”：在调试或实验模式下让实际校园地图改用选择器结果。
3. 也可以继续做“点位图图例/可读性优化”：在任务视图内增加更紧凑的颜色图例或高亮当前聚焦点。
