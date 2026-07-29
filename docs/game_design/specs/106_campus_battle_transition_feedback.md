# 106 校园进入学术交流转场反馈

## 目标

从校园地图进入卡牌战斗时，增加一层短暂的“进入学术交流”转场提示，让探索层和回合制战斗层之间的切换更顺滑。

这一步承接 [105_campus_pickup_burst_feedback.md](105_campus_pickup_burst_feedback.md)。105 强化资源拾取瞬间反馈，106 强化进入战斗/学术交流的场景切换反馈。

## UI 规则

- 转场显示在独立 `TransitionLayer` 中，层级高于 `BattleLayer`。
- 转场文案为标题 `进入学术交流` 和当前交互点副标题，例如 `数据清洗夜 · N009`。
- 转场使用淡入、短暂停留、淡出的 Tween。
- 转场 `mouse_filter` 为忽略，不拦截战斗层 UI 点击。
- 资源点拾取不触发该转场。
- 返回校园、阶段重置或转场自然结束时，转场层都应隐藏。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `transition_layer`、`transition_root`、`transition_title_label`、`transition_subtitle_label`。
  - 新增 `get_transition_visible()`、`get_transition_title_text()`、`get_transition_subtitle_text()`，用于自动化验证。
  - `_build_scene_tree()` 创建 `TransitionLayer`，层级为 3。
  - `_build_transition_layer()` 创建全屏暗色遮罩和居中文字。
  - `_open_battle_for_interactable()` 在战斗层初始化后调用 `_show_battle_transition()`。
  - `_hide_battle_transition()` 在返回校园和重置校园时清理转场。

## 验证记录

脚本加载验证：

```text
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_map_marker.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

进入战斗验证：

```text
scene_reload=0
transition_initial=false
start_ok=true
mode=battle
active_id=data_cleaning_night
transition_visible=true
transition_title=进入学术交流
transition_subtitle=数据清洗夜 · N009
world_visible=false
battle_visible=true
transition_after_return=false
mode_after_return=overworld
```

资源拾取回归验证：

```text
collect_ok=true
mode_after_collect=overworld
transition_after_collect=false
feedback_count=2
```

## 手测重点

1. 运行校园地图。
2. 靠近并进入任意 NPC、事件或 Boss 学术交流。
3. 进入战斗界面时，应短暂显示 `进入学术交流` 和当前节点名。
4. 转场淡出后，战斗 UI 应保持可操作。
5. 点击 `返回校园` 后，转场层不应残留。
6. 拾取资源点时不应出现 `进入学术交流` 转场。

## 下一步

1. 已完成：从学术交流返回校园时会显示轻量结果提示，见 [107_campus_return_transition_feedback.md](107_campus_return_transition_feedback.md)。
2. 加入音效素材后，可以给进入学术交流、返回校园和资源拾取配置不同短音效。
