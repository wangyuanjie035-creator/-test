# 096 校园剧情阶段推进

## 目标

把校园阶段切换从开发期调试按钮接入正式剧情路线。玩家从卡牌战斗层返回校园时，校园会根据当前路线节点自动刷新为对应学业阶段：研一、研二、博一、博二、博三或博四。

这一步重点处理研二后的转博分支：提交 `E005 转博申请` 后进入 `博一` 校园；暂缓转博则继续停留在 `研二` 校园并走 `B003` 硕士毕业线。

## 阶段映射

| 校园阶段 | 路线节点 |
| --- | --- |
| `master1` 研一 | `N001`、`E001`、`N002`、`E004`、`N003`、`N004`、`E003`、`E008`、`B001` |
| `master2` 研二 | `N009`、`B002`、`B003`、`E005` |
| `doctor1` 博一 | `N005`、`B004` |
| `doctor2` 博二 | `N006`、`E006`、`B005` |
| `doctor3` 博三 | `N007`、`B006`、`B007` |
| `doctor4` 博四 | `E007`、`N008`、`B008` |

## 实现规则

- `return_to_campus()` 在结算当前交互后读取战斗层的当前路线节点。
- 如果路线节点映射到新的校园阶段，调用 `_advance_campus_stage_from_story()` 刷新校园。
- 剧情推进刷新会保留 `campus_resources` 和 `interaction_log`，但清空当前阶段的交互完成状态，让新阶段重新生成自己的地图交互池。
- 左上 `阶段` 按钮仍保留为开发期调试入口；手动切换仍会重置资源和日志，避免把调试状态误当成正式流程。
- `BattleState.RUN_PERSISTENT_RESOURCE_IDS` 增加 `reputation`，与 [001_mvp_card_set.md](001_mvp_card_set.md) 中“经费、声望跨节点保留”的规则一致，避免转博后声望被新节点重置。

## 修改文件

- `scripts/overworld/campus_overworld_scene.gd`
  - 新增 `doctor2/doctor3/doctor4` 阶段常量。
  - 新增 `get_campus_stage_for_route_node()` 验证入口。
  - `return_to_campus()` 接入剧情阶段推进。
  - `_reset_campus()` 支持保留资源和日志。
  - 新增路线节点到校园阶段的映射函数。
- `scripts/battle/battle_state.gd`
  - `reputation` 加入跨节点保留资源。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`
- 脚本和场景验证使用 `ResourceLoader.CACHE_MODE_IGNORE`，避免编辑器缓存旧脚本。

脚本编译验证：

```text
res://scripts/battle/battle_state.gd=0
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/run/route_state.gd=0
```

路线节点阶段映射验证：

```text
stage_B001=master1
stage_B002=master2
stage_E005=master2
stage_N005=doctor1
stage_B004=doctor1
stage_N006=doctor2
stage_E006=doctor2
stage_B005=doctor2
stage_N007=doctor3
stage_B006=doctor3
stage_B007=doctor3
stage_E007=doctor4
stage_N008=doctor4
stage_B008=doctor4
```

`E005` 提交转博验证：

```text
submit_started=true
submit_active_before=E005
submit_choice=true
submit_active_after_choice=N005
submit_battle_reputation_after_choice=3
submit_return_stage=doctor1
submit_return_label=博一
submit_methodology=2
submit_paper=1
submit_reputation=3
submit_interactions=10
```

`E005` 暂缓转博验证：

```text
master_started=true
master_choice=true
master_active_after_choice=B003
master_return_stage=master2
master_return_label=研二
master_methodology=1
master_lessons=1
master_interactions=9
```

## 手测要点

1. 运行主场景后默认进入 `研一校园`。
2. 通过路线推进到 `B001` 并领取奖励后，返回校园应切换到 `研二校园`。
3. 在 `研二` 选择 `转博申请`，满足条件后提交申请；返回校园应切换到 `博一校园`。
4. 在 `转博申请` 中选择 `先完成硕士毕业`；返回校园应仍为 `研二校园`，并继续面向 `B003 盲审专家`。
5. 博士线后续节点返回校园时，应依次切到 `博二`、`博三`、`博四`。

## 下一步

1. 已完成：给正式剧情节点增加地图高亮和 HUD 方向提示，见 [097_campus_story_guidance.md](097_campus_story_guidance.md)。
2. 把条件不足的关键节点从“视觉提示”升级为“可选软拦截”，例如允许查看详情但不进入战斗。
3. 后续美术素材到位后，将阶段入口和 Boss 门牌替换成正式像素图标。
