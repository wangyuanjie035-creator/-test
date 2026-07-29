# 136 住屋安全屋与校园日循环

## 目标

把“主题三选一”从单纯调试按钮推进成一次校园探索前的正式入口。

当前 MVP 循环：

```text
住屋安全屋 -> 选择本次校园主题 -> 出门生成校园地图 -> 校园探索/学术交流 -> 安全返回住屋 -> 下一天重随 Seed
```

这个结构参考搜打撤的安全屋节奏：住屋是玩家整理资源和决定下一次探索方向的安全点，校园是带着主题进入的随机地图。

## 设计规则

- 游戏初始化后先进入住屋，而不是直接站在校园地图上。
- 住屋显示当前天数、阶段、Seed、随身资源和本次三选一主题。
- 玩家选择主题后，出门会启用候选池地图，并按该主题生成校园点位。
- 如果玩家暂时没有选择主题，界面显示“未选择”；原型出门时会使用三选一中的第一项作为 fallback，保证流程不断。
- 校园 HUD 暂时提供“安全返回住屋”按钮；地图宿舍入口在 [137_safehouse_map_entrance.md](137_safehouse_map_entrance.md) 中接入。
- 返回住屋后保留资源和日志。
- 点击“下一天”会重随 Seed、清空本次主题选择，并重新生成三选一候选。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `MODE_SAFEHOUSE`。
  - 新增 `safehouse_layer`、`safehouse_root`、`safehouse_panel` 等住屋 UI 节点。
  - 新增 `safehouse_day`，用于记录安全屋日循环。
  - 新增 `depart_safehouse_to_campus()`、`return_to_safehouse()`、`advance_safehouse_day()`。
  - `_reset_campus()` 继续负责生成校园地图，但会在出门时保留资源和日志。
  - 住屋主题按钮复用 `generation_theme_choice` 的三选一数据。
  - `generation_candidate_map_enabled` 默认改为 `true`，让随机候选池地图成为主路径。
  - `get_stage_generation_theme_choice_summary()` 在未选择时显示“未选择”，避免把 fallback 误读成玩家已选择。

## 当前原型 UI

住屋层：

```text
住屋
第 1 天 · 研一校园 · Seed 101
随身资源：...
出门主题：已选：未选择；三选一：缓冲主题 / 实验主题 / 写作主题
[缓冲主题] [实验主题] [写作主题]
[出门去校园] [下一天]
```

校园 HUD 测试区：

```text
候选池地图  重随 Seed
主题 1      主题 2      主题 3
调试返回住屋
```

## 验证记录

远程 Godot 执行器验证：

```text
scene_reload=0
initial=mode=safehouse,day=1,stage=master1,seed=101,theme=recovery_day,map=candidate
selected_initial=
choices_initial=已选：未选择；三选一：缓冲主题 / 实验主题 / 写作主题
selected_after_pick=experiment_day
choices_after_pick=已选：实验主题；三选一：缓冲主题 / 实验主题 / 写作主题
after_depart=mode=overworld,day=1,stage=master1,seed=101,theme=experiment_day,map=candidate
spawn=source=candidate,count=12,pool=20,target=12,selected=12,missing_routes=
after_return=mode=safehouse,day=1,stage=master1,seed=101,theme=experiment_day,map=candidate
after_next_day=mode=safehouse,day=2,stage=master1,seed=1962970086,theme=experiment_day,map=candidate
selected_after_next_day=
choices_after_next_day=已选：未选择；三选一：实验主题 / 缓冲主题 / 写作主题
seed_changed=true
```

## 手测重点

1. 运行校园场景后，应先看到住屋面板，而不是直接进入校园探索。
2. 住屋主题三选一未点击时，应显示“已选：未选择”。
3. 点击任意主题后，该主题应高亮，文字应变为“已选：某某主题”。
4. 点击“出门去校园”后，应进入校园探索，地图来源为 `candidate`。
5. 在校园 HUD 点击“安全返回住屋”后，应回到住屋，资源不清空。
6. 点击“下一天”后，天数 +1，Seed 改变，主题选择清空。

## 下一步

1. 地图宿舍/住屋交互点已在 [137_safehouse_map_entrance.md](137_safehouse_map_entrance.md) 中完成。
2. 给住屋增加可成长内容，例如休息、整理卡组、查看导师关系、选择携带物。
3. 让主题选择影响战斗奖励池和校园事件池，而不只影响地图点位选择。
