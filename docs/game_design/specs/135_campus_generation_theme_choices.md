# 135 校园生成主题三选一

## 目标

修正 [134_campus_generation_theme_weighting.md](134_campus_generation_theme_weighting.md) 的“Seed 自动决定主题”方案：主题不再是系统偷偷决定的日程，而是肉鸽式三选一。

当前实现规则：

- Seed 负责生成 3 个主题候选。
- 玩家从 3 个主题里选择 1 个。
- 被选择的主题才会影响候选池打分。
- 没有手动选择时，原型默认使用三选一里的第 1 个，保证场景仍能自动生成。

## 设计意图

主题选择应该像构筑方向的开局分岔，而不是固定日历。

例子：

```text
三选一：同门主题 / 缓冲主题 / 写作主题
```

玩家选择 `写作主题` 后，本次校园地图会更倾向出现写作、草稿、论文碎片、图书馆等点位；选择 `同门主题` 则会更倾向出现同门、合作、会议等点位。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `generation_selected_theme_id`。
  - 新增 `generation_theme_choice_buttons`，在左上“测试”区域显示 3 个主题按钮。
  - 新增 `set_generation_theme_choice(theme_id, reset_current)`。
  - 新增 `get_generation_theme_choice_id()`。
  - 新增 `get_stage_generation_theme_choice_summary()`。
  - `_get_active_generation_theme_id()` 改为优先使用玩家选择；未选择时使用三选一第 1 项。
  - `_get_stage_generation_theme_choice_ids()` 根据阶段和 Seed 生成 3 个可选主题。
  - 切 Seed、切阶段、剧情推进阶段时清空旧主题选择。
  - 主题显示文案从“实验日/写作日”调整为“实验主题/写作主题”，避免误解为固定日期。

## 当前原型 UI

在左上“测试”区域：

```text
候选池地图  重随 Seed
同门主题    缓冲主题    写作主题
```

点击主题按钮后：

- 如果 `候选池地图` 已开启，立即按该主题重刷当前校园。
- 如果 `候选池地图` 未开启，先记录预选主题，后续打开候选池地图时生效。

后续正式版本可以把这三个按钮升级为开局/阶段入口的主题选择面板。

## 验证记录

远程 Godot 执行器验证：

```text
scene_reload=0
choices=已选：同门主题；三选一：同门主题 / 缓冲主题 / 写作主题
select_writing=true
active_after=写作主题｜写作 / 草稿 / 论文碎片 / 图书馆
audit=pool=20,target=12,selected=12,missing=0,focus_hits=7/7,theme=writing_day,theme_hits=5/12
spawn=source=candidate,count=12,pool=20,target=12,selected=12,missing_routes=
```

全阶段抽查：

```text
master1 三选一：同门主题 / 缓冲主题 / 写作主题
master2 三选一：转博主题 / 写作主题 / 委员会主题
doctor1 三选一：项目主题 / 沙龙主题 / 委员会主题
doctor2 三选一：同门主题 / 实验主题 / 数据修补主题
doctor3 三选一：同门主题 / 写作主题 / 委员会主题
doctor4 三选一：同门主题 / 数据修补主题 / 返修主题
```

## 手测重点

1. 打开 `候选池地图` 后，左上测试区应显示 3 个主题按钮。
2. 当前生效主题按钮应高亮。
3. 点击另一个主题按钮后，校园点位应重刷，审查文本中的 `theme=...` 应切换。
4. 切换主题后仍应保持 `pool=20,target=12,selected=12`。
5. 切换主题后 `路线` 行仍应显示 `缺失无`。
6. 点击 `重随 Seed` 后，三选一主题列表可以变化。
7. 切换阶段后，三选一主题应换成该阶段的主题池。

## 下一步

1. 正式“主题选择面板”已在 [136_safehouse_campus_day_loop.md](136_safehouse_campus_day_loop.md) 中推进为住屋出门入口。
2. 可以做“主题选择与奖励池联动”，让写作主题、实验主题、答辩主题影响战斗后的奖励推荐。
3. 可以把校园 HUD 的安全返回按钮改成地图上的住屋/宿舍交互点。
