# 093 校园条件锁定资源需求

## 目标

把 `condition_locked` 地图标记状态接到真实校园资源检查上。玩家切换到研二、博一等阶段时，如果关键事件或 Boss 的前置材料不足，地图上会显示条件不足标记，并在靠近交互时提示当前资源进度。

本版重点是可读性和路线预告：先让玩家知道“这里以后要准备什么”。交互本身暂不硬拦截，正式拦截会在后续剧情推进和阶段结算接入时统一处理。后续已升级为条件不足二次确认软拦截，见 [098_campus_condition_soft_gate.md](098_campus_condition_soft_gate.md)。

## 显示规则

- 未满足资源需求的关键节点使用 `condition_locked` 标记。
- 满足需求后，标记恢复为该交互原本的 `base_marker_state`，例如剧情关键节点恢复为 `story_key`。
- 靠近未满足节点时，交互摘要追加 `准备不足：...`。
- 资源进度使用 `当前值/需求值`，例如 `数据 2/2、草稿 2/3`。
- 多个可替代条件使用 `或`，必须同时满足的条件使用 `、`。
- 已完成或已拾取的交互清空条件提示，避免消失前残留锁定文案。

## 当前条件表

| 节点 | 类型 | 条件 |
| --- | --- | --- |
| `E005 转博申请窗口` | 研二事件 | 声望 2 或草稿 4 |
| `E006 基金申请窗口` | 博一事件 | 经费 2 |
| `B002 中期考核` | 研二 Boss | 数据 2、草稿 3 |
| `B003 盲审专家` | 研三 Boss | 声望 2 或草稿 4 |
| `B004 博士资格考核` | 博一 Boss | 方法论笔记 3 或论文碎片 2 |
| `B005 项目中期检查` | 博二 Boss | 经费 2 或论文碎片 2 |
| `B006 博士预答辩` | 博三 Boss | 论文碎片 3 或声望 2 |
| `B007 博士答辩` | 博三终局 Boss | 方法论笔记 4，并且论文碎片 4 或声望 2 |
| `B008 补答辩` | 博四短路线 Boss | 方法论笔记 3、论文碎片 2 或声望 1 |

## 实现内容

更新：

- `scripts/overworld/campus_interactable.gd`
  - 新增 `base_marker_state`，保存交互原始标记状态。
  - 新增 `requirement_summary`，用于靠近交互时显示资源进度。
  - 新增 `set_marker_state()`、`set_base_marker_state()` 和 `set_requirement_summary()`。
  - `get_interaction_summary()` 会在资源不足时追加 `准备不足` 文案。
- `scripts/overworld/campus_overworld_scene.gd`
  - 新增 `MARKER_STATE_CONDITION_LOCKED`。
  - 新增 `_refresh_condition_marker_states()`，在地图生成、资源拾取和战斗返回后刷新锁定状态。
  - 新增资源需求组判断与格式化辅助函数。
  - 新增 `get_interactable_marker_state()` 和 `get_interactable_requirement_summary()`，用于脚本验证。

未改变：

- 本版不阻止玩家触发对应事件或 Boss；当前最新流程已加入二次确认软拦截，见 [098_campus_condition_soft_gate.md](098_campus_condition_soft_gate.md)。
- 阶段切换按钮仍是开发期调试入口。
- 需求表暂时写在 `CampusOverworldScene` 中，后续应迁移为数据资源。
- `CampusMapMarker` 的图形绘制规则不变，后续仍可替换为正式像素素材。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/overworld/campus_map_marker.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

条件锁定验证：

```text
master2_transfer_state_initial=condition_locked
master2_transfer_req_initial=声望 0/2 或 草稿 0/4
master2_midterm_state_initial=condition_locked
master2_midterm_req_initial=数据 0/2、草稿 0/3
master2_blind_state_initial=condition_locked
master2_blind_req_initial=声望 0/2 或 草稿 0/4
master2_data_after_collect=2
master2_draft_after_collect=2
master2_midterm_state_after_partial=condition_locked
master2_midterm_req_after_partial=数据 2/2、草稿 2/3
master2_transfer_state_after_rep1=condition_locked
master2_transfer_req_after_rep1=声望 1/2 或 草稿 2/4
doctor_funding_state_initial=condition_locked
doctor_funding_req_initial=经费 0/2
doctor_qualification_state_initial=condition_locked
doctor_qualification_req_initial=方法论笔记 0/3 或 论文碎片 0/2
doctor_funds_after_collect=2
doctor_funding_state_after_funds=story_key
doctor_funding_req_after_funds=
doctor_methodology_after_collect=2
doctor_fragments_after_collect=1
doctor_qualification_state_after_partial=condition_locked
doctor_qualification_req_after_partial=方法论笔记 2/3 或 论文碎片 1/2
```

## 手测要点

1. 运行主场景后，点击 `阶段 -> 研二`。
2. 靠近 `转博申请窗口`、`中期考核` 或 `盲审专家`，应看到条件不足标记和 `准备不足` 摘要。
3. 收集研二地图上的 `实验数据包` 和 `归档草稿堆` 后，`中期考核` 应仍然显示缺少草稿。
4. 点击 `阶段 -> 博一`。
5. 靠近 `基金申请窗口`，初始应显示缺少经费；拾取 `项目经费通知` 后，该节点应恢复为剧情关键标记。
6. 靠近 `博士资格考核`，初始应显示方法论笔记或论文碎片不足；拾取部分材料后，摘要应显示新的当前进度。

## 下一步

1. 已完成：把阶段交互池和条件表迁移成 Resource 数据，见 [094_campus_data_resource_migration.md](094_campus_data_resource_migration.md)。
2. 已完成：将条件锁定从“地图预告”升级为二次确认软拦截，见 [098_campus_condition_soft_gate.md](098_campus_condition_soft_gate.md)。
3. 接入正式剧情推进后，用研二 Boss 后的转博选择控制是否进入博士路线。
4. 已完成：在条件表上增加可配置字段，决定某个锁定节点是“仅提示”“二次确认”还是“禁止进入”，见 [099_campus_requirement_intercept_modes.md](099_campus_requirement_intercept_modes.md)。
