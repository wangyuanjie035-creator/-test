# 087 校园资源点扩展

## 目标

把校园地图从“少量入口 + 单个资源点”推进到可探索的正反馈空间。玩家在进入学术交流前，可以先在不同地点收集草稿、灵感、数据、经费和方法论笔记，再把这些资源带进事件或战斗，形成“探索 -> 构筑条件 -> 事件选择 -> 回写收益”的循环。

## 本次新增资源点

| 交互 ID | 显示名 | 地图语义位置 | 资源结果 | 设计用途 |
| --- | --- | --- | --- | --- |
| `draft_outline` | 草稿提纲 | 宿舍/图书馆附近 | 草稿 +2 | 让 `E001 食堂偶遇大牛` 的草稿选项可自然触发 |
| `quad_inspiration` | 灵感便签 | 校园中庭 | 灵感 +1 | 为后续文献、方向和转化类事件铺资源 |
| `lab_data_sample` | 实验数据 | 实验楼附近 | 数据 +1 | 让实验/中期材料检查更早有地图来源 |
| `funding_notice` | 经费通知 | 导师办公室附近 | 经费 +1 | 为设备维护、项目线和基金事件准备 |

保留原有 `library_notes`：图书馆附近的 `方法论笔记 +1`。

## 生成规则

- 资源点和 NPC/Boss 不再共用“全局洗牌位置”。
- 每个交互点都有明确的基础位置，符合建筑或区域语义。
- 每个交互点使用当前 run seed 做小范围扰动，保持同 seed 可复现，又避免所有局都完全重合。
- 本次仍是固定点位池，没有做路线阶段刷新；后续可按研一、研二、博一等阶段替换资源点和 NPC。

## 收集规则

- 资源交互点仍使用 `CampusInteractable`。
- 收集资源后调用统一的 `_mark_interaction_completed()`。
- 被收集的资源点会隐藏、关闭监听，并进入 `completed_interaction_ids`。
- 资源收集会刷新校园 HUD 和日志。
- 已收集资源会在进入战斗或事件时注入 `BattleState.resources`。
- 事件或战斗完成后，资源正负差值会同步回校园层。

## 实现内容

更新：
- `scripts/overworld/campus_overworld_scene.gd`
  - 扩展 `_spawn_interactables()`，新增 4 个校园资源点。
  - 新增 `_jitter_position()`，用 seed 对固定语义点位做小范围扰动。
  - `_collect_resource()` 改为走 `_mark_interaction_completed()`，让资源点和 NPC/事件完成状态统一。

未改变：
- 卡牌战斗内部资源规则不变。
- 事件选项条件不变。
- 旧的 `library_notes` 资源点仍存在。
- 校园主场景和战斗测试场景入口不变。

## 验证记录

验证环境：
- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/overworld/campus_overworld_scene.gd=0
res://scripts/overworld/campus_interactable.gd=0
res://scripts/ui/battle_test_scene.gd=0
```

交互点池验证：

```text
ids=library_peer,lab_queue,canteen_scholar,advisor_drop_in,proposal_room,library_notes,draft_outline,quad_inspiration,lab_data_sample,funding_notice
count=10
```

草稿资源带入事件验证：

```text
collect_draft=true
draft_after_collect=2
draft_completed=true
available_after_draft=9
start_canteen=true
active_node=E001
battle_draft_injected=2
show_draft_choice=true
draft_after_event=0
reputation_after_event=2
methodology_after_event=1
available_after_event=8
```

其他资源点验证：

```text
collect_inspiration=true
collect_data=true
collect_funds=true
inspiration_after_collect=1
data_after_collect=1
funds_after_collect=1
```

## 手测要点

1. 运行主场景进入校园地图。
2. 在宿舍/图书馆附近寻找 `草稿提纲`，互动后 HUD 应显示 `草稿 2`。
3. 进入 `食堂偶遇大牛`，事件选项 `递上自己的草稿` 应变为可选。
4. 选择该选项后返回校园，HUD 中 `草稿` 应被扣除，`声望` 和 `方法论笔记` 应增加。
5. 分别收集 `灵感便签`、`实验数据`、`经费通知`，确认它们只会被收集一次，并会从地图上消失。

## 下一步

1. 已完成：[088_campus_resource_visual_feedback.md](088_campus_resource_visual_feedback.md) 给资源点增加分类小图标、脉冲提示和拾取浮字。
2. 把校园资源点和路线阶段绑定，进入研二、博一、博二后刷新不同地点内容。
3. 增加可重复的轻量校园遭遇，让地图探索不只服务于一次性拾取。
