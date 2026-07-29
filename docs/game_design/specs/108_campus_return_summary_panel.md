# 108 校园返回摘要面板

## 目标

从学术交流返回校园后，在 HUD 右上角显示一个非阻塞摘要面板，集中展示本次返回的关键变化：

- 结果：节点暂未完成或已完成。
- 资源：本次从战斗/事件带回校园的资源变化。
- 下一步：当前校园剧情引导。

这一步承接 [107_campus_return_transition_feedback.md](107_campus_return_transition_feedback.md)。107 提供短暂转场提示，108 提供更易回看的结构化信息。

## UI 规则

- 摘要面板显示在 HUD 右上角，不遮挡左上状态面板和底部交互提示。
- 面板标题为 `返回摘要`。
- 面板包含三行：`结果：...`、`资源：...`、`下一步：...`。
- 资源无变化时显示 `资源：无变化`。
- 如果结果文本包含 `带回：...`，资源变化会拆到资源行，结果行只保留完成状态。
- 面板不拦截鼠标输入，会自动淡入、短暂停留、淡出。
- 资源点拾取不触发返回摘要面板。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `ReturnSummaryPanel` 及三条摘要 Label。
  - 新增 `get_return_summary_visible()`、`get_return_summary_result_text()`、`get_return_summary_resource_text()`、`get_return_summary_guidance_text()`。
  - `_resolve_active_battle_interaction()` 缓存本次带回资源条目。
  - `return_to_campus()` 在校园刷新和剧情阶段推进后调用 `_show_return_summary_panel()`。
  - `_show_return_summary_panel()` 填充结果、资源和下一步文本，并用 Tween 淡入/淡出。
  - `_open_battle_for_interactable()` 和 `_reset_campus()` 会清理旧摘要面板。

## 验证记录

脚本加载验证：

```text
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_map_marker.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

未完成返回验证：

```text
summary_initial=false
start_ok=true
summary_during_battle=false
mode_after_return=overworld
summary_visible=true
summary_result=结果：回到校园，数据清洗夜 路 N009 暂未完成
summary_resource=资源：无变化
summary_guidance=下一步：会议室方向 · 中期考核 · B002（准备不足：数据 0/2、草稿 0/3；建议：前往复现数据包、归档草稿）
transition_title=回到校园
```

完成事件并带回资源验证：

```text
start_ok=true
choice_ok=true
summary_result=结果：完成：食堂偶遇大牛 路 E001
summary_resource=资源：灵感 +2、声望 +1、方法论笔记 +1
summary_guidance=下一步：会议室方向 · 开题报告 · B001
completed=true
```

回归验证：

```text
collect_ok=true
summary_after_collect=false
feedback_count=2
summary_after_return=true
first_start_ok=true
second_start_ok=true
summary_after_second_start=false
mode_after_second_start=battle
```

## 手测重点

1. 运行校园地图。
2. 进入普通学术交流后不完成，直接点击 `返回校园`。
3. HUD 右上角应显示 `返回摘要`，包含“暂未完成”、“资源：无变化”和当前下一步。
4. 进入事件并完成一个选项后返回校园，摘要应显示完成状态和带回资源。
5. 摘要显示期间，校园移动、交互和 HUD 不应被阻塞。
6. 拾取资源点时不应出现返回摘要面板。

## 下一步

1. 已完成：摘要面板中的下一步目标会同步强化地图剧情目标，见 [109_campus_summary_next_step_link.md](109_campus_summary_next_step_link.md)。
2. 后续可加入手动关闭按钮或历史记录面板，但当前阶段先保持非阻塞和短暂显示。
