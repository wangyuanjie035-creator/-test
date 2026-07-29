# 125 候选池接入开关

## 目标

承接 [124_campus_candidate_pool_expansion.md](124_campus_candidate_pool_expansion.md)，增加一个调试/实验开关，让实际校园地图可以从“固定 12 点”切换到“候选池选择器生成 12 点”。

本步默认仍关闭候选池地图，玩家正常运行项目时继续看到原来的固定地图。开关只用于原型验证，方便后续测试随机校园地图的节奏、主题覆盖和主线安全性。

## 交互规则

- 左上 HUD 的“测试”区域新增 `候选池地图` 开关。
- 默认关闭：`_spawn_interactables()` 使用阶段 `interactions`。
- 打开后：`_spawn_interactables()` 使用候选池选择器结果。
- 切换开关会重刷当前校园，但保留随身资源和日志。
- 战斗层中开关禁用，避免学术交流中途改写校园点位。
- 状态行和右上任务视图只在开关打开时追加 `候选池` 标记。

## 剧情路线保护

候选池选择器按标签和 seed 选点，但实际刷地图时还需要保证主线入口不会消失。本步在候选模式下额外做路线保护：

1. 先读取 123/124 的候选池选择结果。
2. 检查当前阶段的剧情路线顺序，例如研二的 `B002/E005/B003`。
3. 如果某个路线节点完全缺失，则从候选池中补入该路线的最佳候选。
4. 如果因此超过目标数量，则移除非路线保护的低优先级点。

这样调试模式可以产生地图差异，同时不破坏“下一步”目标、剧情 Boss 和转博/毕业链路。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `generation_candidate_map_enabled`。
  - 新增 `GenerationCandidateToggle` 调试开关。
  - `_spawn_interactables()` 改为读取 `_get_stage_spawn_interaction_definitions()`。
  - `_get_stage_spawn_interaction_definitions()` 默认回到固定 `interactions`，候选模式使用 `_get_stage_generation_spawn_definitions()`。
  - `_get_stage_generation_spawn_definitions()` 增加剧情路线保护。
  - 新增 `get_stage_spawn_source_summary()`、`get_stage_spawn_interaction_ids_summary()`、`get_stage_spawn_missing_route_node_summary()`，用于审查和远程验证。

## 验证记录

远程 Godot 执行器验证：

```text
scene_reload=0
default_enabled=false
default_summary=source=fixed,count=12,pool=16,target=12,selected=12,missing_routes=
candidate_enabled=true
candidate_summary=source=candidate,count=12,pool=16,target=12,selected=12,missing_routes=
```

研一固定模式和候选模式点位存在差异：

```text
fixed=library_peer,lab_queue,canteen_scholar,advisor_drop_in,proposal_room,library_notes,draft_outline,quad_inspiration,lab_data_sample,funding_notice,reading_group_quiz,peer_contact_card
candidate=peer_literature_swap,advisor_feedback_note,lab_data_sample,proposal_room,advisor_drop_in,quad_inspiration,library_peer,peer_contact_card,draft_outline,reading_group_quiz,canteen_scholar,library_notes
```

六阶段候选模式路线安全验证：

```text
master1 source=candidate,count=12,pool=16,target=12,selected=12,missing_routes= actual=12 target=B001
master2 source=candidate,count=12,pool=16,target=12,selected=12,missing_routes= actual=12 target=B002
doctor1 source=candidate,count=12,pool=16,target=12,selected=12,missing_routes= actual=12 target=N005
doctor2 source=candidate,count=12,pool=16,target=12,selected=12,missing_routes= actual=12 target=N006
doctor3 source=candidate,count=12,pool=16,target=12,selected=12,missing_routes= actual=12 target=N007
doctor4 source=candidate,count=12,pool=16,target=12,selected=12,missing_routes= actual=12 target=E007
```

## 手测重点

1. 不打开开关时，地图点位、主线目标和右上任务视图应与之前一致。
2. 打开 `候选池地图` 后，左上状态行和右上阶段行应显示 `候选池`。
3. 打开后当前校园应重刷，实际可互动点仍是 12 个，不是 16 个。
4. 打开后主线目标仍应存在，例如研二仍能看到 `B002 中期考核`。
5. 切到不同阶段后，开关状态应保留，且每阶段仍能显示有效主线目标。
6. 进入学术交流时开关应不可用，返回校园后再继续测试。

## 下一步

1. 已完成“候选地图 Seed 差异测试”，见 [126_campus_seed_reroll_debug.md](126_campus_seed_reroll_debug.md)。
2. 已完成“候选池点位布局权重”，见 [127_campus_candidate_layout_weighting.md](127_campus_candidate_layout_weighting.md)。
