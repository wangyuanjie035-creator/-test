# 114 校园 HUD 信息密度审查

## 目标

承接 [113_campus_hud_visual_hierarchy.md](113_campus_hud_visual_hierarchy.md)，整理左上角 `StatusPanel` 的内部信息层级。当前校园地图已经有阶段、seed、随身资源、下一步目标、目标图例、今日记录和阶段调试按钮；如果继续平铺在同一个竖排里，后续加入任务列表、小地图或状态异常时会越来越难读。

这一版不新增浮层，也不改变玩法逻辑，只把左上 HUD 改为更清晰的分区结构：状态、资源、目标、日志、测试。

## 体验规则

- 左上 HUD 仍然是单一面板，避免在校园地图上叠出过多卡片。
- `状态` 区显示阶段、seed 和当前模式，是第一眼确认当前校园进程的位置。
- `资源` 区单独承载随身资源，并允许长文本自动换行。
- `目标` 区承载下一步剧情目标和青色/金色图例。
- `日志` 区使用更弱的文字颜色，作为回顾信息，不抢目标提示优先级。
- `测试` 区保留阶段切换按钮，但用更小字号、更低透明度呈现，明确它是原型验证入口。
- 本步不改变资源数值、剧情目标、地图标记、方向箭头、返回摘要和战斗入口。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `HUD_STATUS_PANEL_WIDTH` 和 HUD 面板/文字/分隔线颜色常量。
  - `StatusPanel` 改为顶部左侧锚点，并应用暗色 `StyleBoxFlat` 面板样式。
  - 新增 `_create_hud_panel_style()`、`_create_hud_section()` 和 `_add_hud_section_rule()`。
  - 将原有状态、资源、目标、图例、日志拆入 `OverviewSection`、`ResourceSection`、`GuidanceSection`、`LogSection`。
  - `_build_stage_debug_controls()` 改为 `DebugSection`，增加说明文本并弱化按钮视觉权重。
  - 新增 `get_status_panel_rect()` 和 `get_hud_status_section_summary()`，用于布局与结构验证。

## 验证记录

脚本加载验证：
```text
campus_reload=0
indicator_reload=0
```

结构验证目标：
```text
sections=OverviewSection,ResourceSection,GuidanceSection,LogSection,DebugSection
stage_debug_buttons=6
master1_disabled=true
z_order=status=10,direction=20,prompt=30,summary=40
guidance_text=下一步：会议室方向 · 开题报告 · B001
```

## 手测重点

1. 运行校园地图后，左上面板应显示明确分区：状态、资源、目标、日志、测试。
2. 资源较多时，资源文本应在面板内换行，而不是挤出左上面板。
3. 下一步目标和图例应仍位于目标区，且青色/金色含义不变。
4. 今日记录应弱于目标提示，但仍能读清。
5. 阶段切换按钮仍可点击，当前阶段按钮仍处于禁用状态。
6. 返回摘要、底部交互提示和方向箭头的层级不应被这次 HUD 分区影响。

## 下一步

1. 已完成：校园交互内容补强已为每个阶段新增学术交流点和补给点，见 [115_campus_stage_interaction_variety_pack.md](115_campus_stage_interaction_variety_pack.md)。
2. 后续如果需要任务列表或小地图，应复用本次 HUD 分区和 113 的安全区规则。
