# 126 候选地图 Seed 差异测试

## 目标

承接 [125_campus_candidate_spawn_toggle.md](125_campus_candidate_spawn_toggle.md)，给校园调试区增加轻量 seed 切换能力，让测试者不用重启项目就能观察不同 seed 下的候选池地图组合。

本步仍是调试功能，不改变正式玩法入口。它服务两个目标：

- 复现：同一个 seed 下，候选池地图点位组合应保持一致。
- 差异：不同 seed 下，候选池地图可以出现不同点位组合。

## 交互规则

- 左上 HUD 的“测试”区域新增 `重随 Seed` 按钮。
- 点击后生成一个新的 `campus_seed`，并重刷当前阶段校园。
- 当前开关状态会保留：如果已经打开 `候选池地图`，重随后仍以候选池模式刷图。
- 切换 seed 会保留随身资源和日志，但会清空当前阶段已处理点位，这是调试重刷的预期行为。
- 战斗层中按钮禁用，避免学术交流中途重刷校园。
- 状态行和右上任务视图继续显示当前 Seed。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `CAMPUS_SEED_MAX`。
  - 新增 `reroll_seed_button`。
  - 新增 `get_campus_seed()`、`set_campus_seed()`、`reroll_campus_seed()`。
  - 新增 `_generate_debug_campus_seed()`。
  - `重随 Seed` 按钮复用当前 `_reset_campus(true, true)` 流程，避免新增一条平行重刷路径。

## 验证记录

远程 Godot 执行器验证：

```text
scene_reload=0
same_seed_same=true
different_seed_diff=true
reroll=old=2,new=625141149,changed=true,summary=source=candidate,count=12,pool=16,target=12,selected=12,missing_routes=
```

研一候选池地图示例：

```text
seed_1=peer_literature_swap,advisor_feedback_note,lab_data_sample,proposal_room,advisor_drop_in,quad_inspiration,library_peer,peer_contact_card,draft_outline,reading_group_quiz,canteen_scholar,library_notes
seed_2=peer_literature_swap,advisor_feedback_note,lab_data_sample,proposal_room,advisor_drop_in,quad_inspiration,library_peer,draft_outline,peer_contact_card,reading_group_quiz,canteen_scholar,funding_notice
```

## 手测重点

1. 默认固定地图模式下点击 `重随 Seed`，地图仍应是固定阶段点位，只是位置扰动可能变化。
2. 打开 `候选池地图` 后点击 `重随 Seed`，点位组合可以变化，但实际可互动点仍应是 12 个。
3. 重随后左上状态行和右上任务视图的 Seed 应同步变化。
4. 相同 seed 通过 `set_campus_seed()` 复现时，候选池点位组合应一致。
5. 重随后主线目标仍应存在，`missing_routes` 应为空。
6. 进入学术交流时 `重随 Seed` 按钮应禁用。

## 下一步

1. 已完成“候选池点位布局权重”，见 [127_campus_candidate_layout_weighting.md](127_campus_candidate_layout_weighting.md)。
2. 已完成“候选地图审查面板”，见 [128_campus_candidate_audit_panel.md](128_campus_candidate_audit_panel.md)。
