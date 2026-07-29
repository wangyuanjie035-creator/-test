# 130 校园点位图例

## 目标

承接 [129_campus_marker_visual_variety_placeholders.md](129_campus_marker_visual_variety_placeholders.md)，在左上 HUD 的“测试”区域增加点位图例，解释当前地图中出现的像素风 profile。

本步只增加调试/手测信息，不改变地图生成、点位触发、路线推进、战斗入口或资源回写。

## 图例规则

- 图例位于候选地图审查面板下方。
- 图例只显示当前地图实际出现的 profile。
- 图例随切换阶段、打开/关闭 `候选池地图`、点击 `重随 Seed` 自动刷新。
- 每个条目格式为：

```text
导师=便签×1
```

含义：

- `导师`：profile 的玩法语义。
- `便签`：地图上的像素占位形状。
- `×1`：当前地图出现数量。

## 示例

固定研一：

```text
图例：导师=便签×1 / 同门=双人×2 / 设备=仪器×1 / 委员会=门×1 / 行政=公告×1 / 数据=样本×1 / 草稿=纸页×1 / 经费=票据×1 / 灵感=灯泡×1 / 笔记=本子×1 / 补给=箱×1
```

候选池研一：

```text
图例：导师=便签×1 / 同门=双人×2 / 委员会=门×1 / 行政=公告×1 / 数据=样本×1 / 草稿=纸页×1 / 灵感=灯泡×1 / 笔记=本子×2 / 论文=碎片×1 / 补给=箱×1
```

候选池博三：

```text
图例：委员会=评审席×3 / 答辩=门×2 / 事件=公告×1 / 草稿=纸页×1 / 灵感=灯泡×1 / 论文=碎片×3 / 补给=箱×1
```

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `marker_profile_legend_label`。
  - 新增 `get_marker_visual_profile_legend_text()`。
  - 新增 `_get_marker_visual_profile_counts()`，复用 marker profile 统计。
  - 新增 profile 图例排序与中文映射。
  - 新增 `_refresh_marker_profile_legend()`，接入测试区刷新流程。

## 验证记录

远程 Godot 执行器验证：

```text
scene_reload=0
seed_changed=true
legend_length=70
summary=committee_panel=3,defense_gate=2,draft_cache=1,inspiration_cache=1,notice_board=1,paper_cache=3,resource_cache=1
has_defense_profile=true
has_committee_profile=true
```

输出抽查：

```text
fixed_legend=图例：导师=便签×1 / 同门=双人×2 / 设备=仪器×1 / 委员会=门×1 / 行政=公告×1 / 数据=样本×1 / 草稿=纸页×1 / 经费=票据×1 / 灵感=灯泡×1 / 笔记=本子×1 / 补给=箱×1
candidate_legend=图例：导师=便签×1 / 同门=双人×2 / 委员会=门×1 / 行政=公告×1 / 数据=样本×1 / 草稿=纸页×1 / 灵感=灯泡×1 / 笔记=本子×2 / 论文=碎片×1 / 补给=箱×1
doctor3_legend=图例：委员会=评审席×3 / 答辩=门×2 / 事件=公告×1 / 草稿=纸页×1 / 灵感=灯泡×1 / 论文=碎片×3 / 补给=箱×1
```

## 手测重点

1. 左上“测试”区域审查文本下方应显示 `图例：...`。
2. 固定地图和候选池地图的图例可以不同。
3. 点击 `重随 Seed` 后，如果候选点组合变化，图例数量也应同步变化。
4. 切换到博三时，应能看到 `答辩=门`、`委员会=评审席` 等博士阶段语义。
5. 图例不应遮挡右上任务视图、底部交互提示或角色移动区域。

## 下一步

1. 可以继续扩展每阶段候选池到 20 个以上，让 profile 图例更稳定地覆盖更多校园内容。
2. “正式美术素材替换清单”已在 [131_campus_art_asset_replacement_checklist.md](131_campus_art_asset_replacement_checklist.md) 中补齐，后续可以按该清单接入贴图 fallback。
