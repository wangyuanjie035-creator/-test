# 119 校园 NPC/点位内容标签

## 目标

承接 [118_campus_focus_info_card.md](118_campus_focus_info_card.md)，为校园交互点增加内容标签。标签用于描述点位的语义身份，例如导师、同门、实验室、设备、会议、委员会、答辩、补给、写作等。

本步不改变移动、触发、战斗、资源和阶段推进规则，只补一层可查询、可展示、可继续扩展的数据。后续替换像素素材、筛选随机事件、控制地图内容密度时，都可以优先读取这些标签。

## 体验规则

- 靠近校园点位时，信息卡的“类型”行会追加最多 3 个高信号内容标签。
- 完整标签可以通过调试 getter 查询，不需要全部挤进 HUD。
- 显式标签优先；没有显式标签的旧点位会根据交互类型、资源类型和路线 ID 推断基础标签。
- 标签 ID 使用英文稳定键，例如 `peer`、`advisor`、`lab`、`committee`、`writing`。
- 中文显示名只在界面层映射，避免后续改文案时影响数据、素材命名和筛选逻辑。
- 同一显示名会在信息卡中去重，避免 `encounter` 与 `academic_exchange` 同时显示成重复的“学术交流”。

## 实现记录

- [campus_interaction_definition.gd](../../../scripts/data/campus_interaction_definition.gd)
  - 新增 `content_tags: Array[StringName]`，让 `.tres` 阶段数据可以显式标注点位语义。
- [campus_interactable.gd](../../../scripts/overworld/campus_interactable.gd)
  - 新增运行时 `content_tags` 字段。
  - 新增 `get_content_tags()`，供地图、HUD 和测试脚本读取。
- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - `_add_interactable()` 从交互定义复制 `content_tags` 到运行时节点。
  - 新增 `get_interactable_content_tag_summary()`，查询单个点位的中文标签摘要。
  - 新增 `get_content_tag_distribution_summary()`，查询当前阶段标签分布。
  - 新增 `_normalize_content_tags()`、`_infer_content_tags()`、`_format_content_tags()` 和 `_get_content_tag_display_name()`。
  - `_format_focus_info_type()` 追加 `标签：...`，但不增加信息卡行数。
- [data/campus/stages](../../../data/campus/stages)
  - 为 115 新增的 12 个点位补显式标签，覆盖读书会、同门、预印本、送审、博士沙龙、资格考、跨组会议、合作反馈、委员会模拟、答辩计时、返修互审和返修补给。

## 标签首版约定

| 标签 ID | 显示名 | 用途 |
|---|---|---|
| `peer` | 同门 | 同门、读书会、互审、同行反馈 |
| `advisor` | 导师 | 导师意见、送审清单、导师相关事件 |
| `lab` | 实验室 | 数据、实验样本、设备排期 |
| `equipment` | 设备 | 仪器、排期、设备故障 |
| `meeting` | 会议 | 协调会、组会、项目会 |
| `committee` | 委员会 | 资格考、预答辩、答辩委员会 |
| `defense` | 答辩 | 预答辩、正式答辩、补答辩 |
| `writing` | 写作 | 草稿、论文碎片、返修稿 |
| `resource` | 补给 | 可拾取资源点 |
| `self_care` | 照护 | 灵感、休息、食堂补给 |

## 验证记录

脚本加载：

```text
campus_interaction_definition.gd=0
campus_interactable.gd=0
campus_overworld_scene.gd=0
```

六个阶段标签覆盖：

```text
master1=count=12,empty_tags=0
master2=count=12,empty_tags=0
doctor1=count=12,empty_tags=0
doctor2=count=12,empty_tags=0
doctor3=count=12,empty_tags=0
doctor4=count=12,empty_tags=0
```

研二 `送审清单` 显式标签与信息卡：

```text
review_tags=导师 / 写作 / 方法 / 补给
review_type=类型：补给点 · 校园拾取 | 标签：导师 / 写作 / 方法
```

旧点位兜底推断：

```text
fallback_tags=data_cleaning_night=学术交流
```

## 手测重点

1. 靠近 `送审清单` 时，信息卡类型行应显示导师/写作/方法相关标签。
2. 靠近旧的普通学术交流点时，也应至少显示基础语义标签，不应为空。
3. 信息卡仍应保持五行结构，不应遮住底部交互提示。
4. 切换研一、研二、博一、博二、博三、博四后，每个阶段都应有 12 个点，且无空标签。
5. 标签只改变信息呈现和调试查询，不应影响触发战斗、拾取资源、条件不足二次确认和剧情目标高亮。

## 下一步

1. 已完成“校园小地图/任务栏占位”，见 [120_campus_task_tracker_placeholder.md](120_campus_task_tracker_placeholder.md)。
2. 可以继续做“标签驱动的地图生成草案”：按导师/同门/实验室/补给比例控制随机校园点位池。
