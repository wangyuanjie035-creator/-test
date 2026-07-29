# 100 校园下一步补足建议

## 目标

让校园 HUD 的 `下一步：...` 不只显示目标和材料缺口，还能给出当前阶段可执行的补足建议。玩家看到 `condition_locked` 时，可以直接知道优先去哪个校园资源点，而不是只看一串资源数字。

示例：

```text
下一步：会议室方向 · 中期考核 · B002（准备不足：数据 0/2、草稿 0/3；建议：前往复现数据包、归档草稿）
```

## 建议规则

- 只在下一剧情目标存在 `requirement_summary` 时显示建议。
- 建议来源优先使用当前校园阶段中未拾取的资源交互点。
- `all` 条件会列出当前缺少的每项资源来源。
- `any` 条件会列出可替代的资源来源，用 `或` 连接。
- 如果一个资源需要多个拾取点才能补足，会按当前阶段交互顺序列出多个来源。
- 如果当前阶段没有对应资源点，则退回为 `补足资源名`，避免指向不存在的地图点。
- 建议只改变 HUD 文案，不改变 `condition_locked`、`intercept_mode` 或战斗入口规则。

## 修改文件

- `scripts/overworld/campus_overworld_scene.gd`
  - 新增 `get_story_guidance_supply_hint_text()`，用于验证当前补足建议。
  - `_format_story_guidance_text()` 在准备不足文案后追加 `；建议：...`。
  - 新增需求建议辅助函数，按路线需求组和当前阶段资源点生成建议。

## 验证记录

验证环境：
- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`
- 脚本和场景验证使用 `ResourceLoader.CACHE_MODE_IGNORE`。

脚本编译验证：

```text
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/overworld/campus_map_marker.gd=0
res://scripts/data/campus_route_requirement_definition.gd=0
```

典型引导文案验证：

```text
master2_advice=建议：前往复现数据包、归档草稿
master2_text=下一步：会议室方向 · 中期考核 · B002（准备不足：数据 0/2、草稿 0/3；建议：前往复现数据包、归档草稿）
doctor1_advice=建议：前往委员会沟通笔记 或 论文主线碎片
doctor1_text=下一步：会议室方向 · 博士资格考核 · B004（准备不足：方法论笔记 0/3 或 论文碎片 0/2；建议：前往委员会沟通笔记 或 论文主线碎片）
doctor2_advice=建议：前往经费批复 或 项目论文碎片
doctor2_text=下一步：会议室方向 · 项目中期检查 · B005（准备不足：经费 0/2 或 论文碎片 0/2；建议：前往经费批复 或 项目论文碎片）
```

## 手测要点

1. 运行主场景后切到 `研二`，HUD 下一步应指向 `B002 中期考核`。
2. 资源不足时，HUD 应显示 `建议：前往复现数据包、归档草稿`。
3. 拾取 `复现数据包` 后，建议应只剩缺少草稿相关的资源点或补足提示。
4. 完成 `N005 博一问题链重构` 后，博一下一步应指向 `B004 博士资格考核`，并显示方法论笔记或论文碎片的可替代建议。
5. 完成 `N006` 和 `E006` 后，博二下一步应指向 `B005 项目中期检查`，并显示经费或论文碎片的可替代建议。
6. 资源满足后，下一步 HUD 不应再显示准备不足或建议文案。

## 下一步

1. 已完成：让建议资源点也获得轻量地图高亮，形成“目标点 + 补给点”的双引导，见 [101_campus_supply_hint_marker_highlight.md](101_campus_supply_hint_marker_highlight.md)。
2. 后续可把建议改为更完整的路线句式，例如“先去复现数据包，再回会议室挑战中期考核”。
3. 美术素材到位后，把补足建议对应到正式像素路标、公告栏或 NPC 提醒。
