# 122 标签驱动的地图生成草案

## 目标

承接 [121_campus_task_tracker_minimap_points.md](121_campus_task_tracker_minimap_points.md)，开始把“导师、同门、实验室、设备、会议、补给、答辩、返修”等内容标签用于校园地图生成规划。

本步不直接替换现有固定阶段池，也不改变地图移动、点位触发、资源、战斗和剧情推进。当前实现先给每个阶段补一份“生成配方”，并提供审查接口，确认现有固定池是否满足未来随机校园的标签约束。

## 生成草案规则

- 每个阶段保留目标点位数，当前为 12。
- `generation_focus_tags` 表示阶段风味标签，用于未来随机抽取权重。
- `generation_required_tags` 表示阶段最低覆盖标签，用于避免随机地图缺少关键体验。
- 固定池继续照常加载；审查接口只读当前固定池，不会改写点位。
- 旧点位如果没有显式 `content_tags`，会根据交互类型、资源类型和路线 ID 推断标签。
- 审查通过的标准是：目标点数一致、required tags 缺失为 0、focus tags 至少能在当前池中命中。

## 阶段配方

| 阶段 | Focus Tags | Required Tags |
|---|---|---|
| 研一 | 同门、导师、实验室、图书馆、写作、照护、补给 | 同门、导师、实验室、写作、补给、Boss、事件 |
| 研二 | 数据、草稿、写作、导师、委员会、设备、论文碎片 | 数据、草稿、写作、导师、委员会、补给、事件、Boss |
| 博一 | 项目、委员会、考核、经费、数据、写作、沙龙 | 项目、委员会、考核、补给、数据、写作、事件、Boss |
| 博二 | 项目、设备、合作、会议、经费、数据 | 项目、设备、合作、会议、补给、事件、Boss |
| 博三 | 答辩、委员会、写作、论文碎片、声望、方法 | 答辩、委员会、写作、论文碎片、补给、Boss、学术交流 |
| 博四 | 返修、答辩、委员会、写作、照护、同门 | 返修、答辩、委员会、写作、照护、补给、Boss |

## 实现记录

- [campus_stage_definition.gd](../../../scripts/data/campus_stage_definition.gd)
  - 新增 `generation_target_interaction_count`。
  - 新增 `generation_focus_tags`。
  - 新增 `generation_required_tags`。
- [data/campus/stages](../../../data/campus/stages)
  - 为研一、研二、博一、博二、博三、博四补阶段生成配方。
- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 路线 ID 推断标签扩展到导师、设备、项目、答辩、返修等语义。
  - 新增 `get_stage_generation_profile_summary()`。
  - 新增 `get_stage_generation_focus_mix_summary()`。
  - 新增 `get_stage_generation_missing_tag_summary()`。
  - 新增 `get_stage_generation_tag_audit_summary()`。

## 验证记录

脚本加载：

```text
campus_stage_definition.gd=0
campus_overworld_scene.gd=0
```

六阶段配方审查：

```text
master1=target=12,current=12,required=7,missing=0,focus_hits=7/7
master2=target=12,current=12,required=8,missing=0,focus_hits=7/7
doctor1=target=12,current=12,required=8,missing=0,focus_hits=7/7
doctor2=target=12,current=12,required=7,missing=0,focus_hits=6/6
doctor3=target=12,current=12,required=7,missing=0,focus_hits=6/6
doctor4=target=12,current=12,required=7,missing=0,focus_hits=6/6
```

研二示例：

```text
profile=target=12,focus=数据 / 草稿 / 写作 / 导师 / 委员会 / 设备 / 论文碎片,required=数据 / 草稿 / 写作 / 导师 / 委员会 / 补给 / 事件 / Boss
mix=数据=3、草稿=2、写作=7、导师=2、委员会=2、设备=2、论文碎片=2
missing=
```

## 手测重点

1. 切换六个校园阶段后，固定点位数量仍应为 12。
2. 任务视图、点位图、剧情目标和建议补给仍应照常刷新。
3. 研二仍应优先指向 `B002 中期考核`，补给建议仍应指向 `复现数据包、归档草稿`。
4. 标签配方只影响审查和未来生成规划，不应改变当前固定地图点位。
5. 后续新增点位时，若 required tags 缺失，应能通过审查接口暴露。

## 下一步

1. 已完成“标签驱动的候选池选择器”，见 [123_campus_tag_candidate_selector.md](123_campus_tag_candidate_selector.md)。
2. 可以继续做“交互候选库扩容”：为每个阶段准备多于 12 个候选点，让选择器真正产生差异。
