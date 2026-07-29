# 118 校园点位靠近信息卡

## 目标

承接 [117_campus_marker_role_silhouettes.md](117_campus_marker_role_silhouettes.md)，在玩家靠近校园交互点时，除了底部一句交互提示，再显示一个轻量结构化信息卡。这样玩家可以在地图探索时直接判断：这是学术交流、事件、Boss 还是补给点；它通向哪条路线；大致收益是什么；是否需要准备材料。

本步不改变交互触发方式，不改变路线、战斗、资源和条件判定，只增强靠近时的信息呈现。

## 体验规则

- 信息卡只在靠近交互点时出现，离开后隐藏。
- 信息卡位于底部交互提示上方，并与底部提示保持安全间距。
- 底部交互提示仍保留最高操作优先级，用于显示“确认进入/材料不足”等短文本。
- 信息卡显示五行结构：名称、类型、路线、收益、准备。
- 补给点显示具体资源收益，例如 `+1 方法论笔记`。
- Boss、事件和学术交流显示收益倾向，例如 Boss 奖励、事件选项、卡牌奖励。
- 条件不足时，准备行显示缺口和入口规则，例如可二次确认、仅提示或无法进入。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `HUD_Z_FOCUS_INFO` 和 `HUD_FOCUS_INFO_PANEL_WIDTH`。
  - 新增 `FocusInfoPanel` 及 `Title/Type/Route/Reward/Requirement` 五个 Label。
  - 新增 `_build_focus_info_panel()` 和 `_create_focus_info_label()`。
  - `_refresh_hud()` 中新增 `_refresh_focus_info_panel()`。
  - 新增 `_format_focus_info_title()`、`_format_focus_info_type()`、`_format_focus_info_route()`、`_format_focus_info_reward()` 和 `_format_focus_info_requirement()`。
  - 新增验证 getter：`get_focus_info_panel_visible()`、`get_focus_info_panel_rect()`、`get_focus_info_summary_text()` 等。

## 验证记录

脚本加载：
```text
campus_reload=0
```

研二 `B002 中期考核` 靠近信息卡：
```text
focus_visible=true
focus_summary=剧情目标 · 中期考核|类型：剧情考核 · Boss|路线：B002|收益：Boss 奖励 / 剧情推进|准备：数据 0/2、草稿 0/3 · 可二次确认
focus_prompt_gap=30.0
```

研二 `送审清单` 补给点信息卡：
```text
resource_focus_summary=送审清单|类型：补给点 · 校园拾取|路线：无 · 直接获得资源|收益：+1 方法论笔记|准备：无需准备
```

清空焦点后：
```text
focus_after_clear=false
```

## 手测重点

1. 靠近普通学术交流点时，信息卡应显示 `类型：学术交流 · 卡牌构筑`。
2. 靠近事件点时，信息卡应显示 `类型：校园事件 · 选项处理`。
3. 靠近 Boss 点时，信息卡应显示路线 ID、Boss 奖励倾向和准备条件。
4. 靠近补给点时，信息卡应显示具体资源收益。
5. 离开交互范围后，信息卡应隐藏，底部提示回到 `校园中庭`。
6. 信息卡不应遮住底部交互提示，也不应影响返回摘要和方向箭头。

## 下一步

1. 已完成“校园 NPC 内容标签”，见 [119_campus_content_tags.md](119_campus_content_tags.md)。
2. 可以继续做“校园小地图/任务栏占位”：在 HUD 安全区内增加轻量任务视图，为后续更大的随机校园做准备。
