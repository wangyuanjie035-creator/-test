# 107 校园返回结果提示

## 目标

从学术交流返回校园时，显示一层短暂结果提示，让玩家更清楚这次返回意味着什么：

- 节点暂未完成。
- 节点已完成。
- 带回了资源变化。

这一步承接 [106_campus_battle_transition_feedback.md](106_campus_battle_transition_feedback.md)。106 解决“进入战斗”的场景衔接，107 解决“回到校园”的结果衔接。

## UI 规则

- 复用 `TransitionLayer`。
- 返回标题固定为 `回到校园`。
- 副标题使用 `return_to_campus()` 生成的结果日志摘要，例如 `回到校园，数据清洗夜 路 N009 暂未完成`。
- 副标题支持自动换行，避免较长的“完成/带回资源”文本横向溢出。
- 资源点拾取不触发返回提示。
- 返回提示不改变战斗结算、资源回写、剧情阶段推进或校园刷新规则。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - `return_to_campus()` 不再在阶段推进时提前返回；会在刷新/推进后统一显示返回提示。
  - 新增 `_show_campus_return_transition()`。
  - 新增 `_show_transition_message()`，让进入战斗和返回校园共用 Tween 逻辑。
  - 新增 `_format_campus_return_transition_subtitle()`，去掉结果文本末尾句号。
  - 转场副标题增加自动换行和固定最小宽度。

## 验证记录

脚本加载验证：

```text
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_map_marker.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

返回校园验证：

```text
scene_reload=0
start_ok=true
enter_transition_title=进入学术交流
enter_transition_subtitle=数据清洗夜 · N009
mode_after_return=overworld
return_transition_visible=true
return_transition_title=回到校园
return_transition_subtitle=回到校园，数据清洗夜 路 N009 暂未完成
world_visible=true
battle_visible=false
```

资源拾取回归验证：

```text
collect_ok=true
mode_after_collect=overworld
transition_after_collect=false
feedback_count=2
data_after_collect=2
```

## 手测重点

1. 运行校园地图。
2. 进入任意 NPC、事件或 Boss 学术交流。
3. 未完成节点时点击 `返回校园`，应短暂显示 `回到校园` 和“暂未完成”摘要。
4. 完成事件或领取奖励后返回校园，应显示完成/带回资源相关摘要。
5. 返回提示显示后，校园地图和 HUD 应保持可操作。
6. 拾取资源点时不应出现 `回到校园` 提示。

## 下一步

1. 已完成：从学术交流返回校园后，HUD 会显示结果、资源和下一步摘要，见 [108_campus_return_summary_panel.md](108_campus_return_summary_panel.md)。
2. 加入音效素材后，可以给进入学术交流、返回校园和资源拾取配置不同短音效。
