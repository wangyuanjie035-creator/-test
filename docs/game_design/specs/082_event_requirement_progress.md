# 事件条件进度显示 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [079_route_node_detail_panel.md](079_route_node_detail_panel.md)
- [080_route_detail_structured_rows.md](080_route_detail_structured_rows.md)
- [081_transfer_branch_requirements.md](081_transfer_branch_requirements.md)

## 目标

把事件选项里的静态条件文本从：

```text
可选 / 需草稿 2
暂不可选 / 需声望 1
```

改成可读的当前进度：

```text
带着提纲过去 | 暂不可选 | 草稿 0/2；消耗 2 草稿，获得 1 论文碎片，将 1 张会后纪要加入牌组。
顺便申请资源 | 可选 | 声望 1/1；获得 1 经费，将 1 张导师沟通加入牌组。
```

玩家不需要记住资源阈值，也不需要进入事件后才知道自己差多少。

## UI 规则

事件详情行改为三列：

| 列 | 内容 |
| --- | --- |
| 名称 | 事件选项名 |
| 状态 | `可选` 或 `暂不可选` |
| 详情 | 条件进度 + 选项预览 |

无条件选项显示：

```text
无条件；失去 2 精力，获得 1 方法论笔记和 1 声望。
```

单资源条件显示：

```text
草稿 0/2
声望 1/1
经费 0/2
论文碎片 2/2
```

二选一资源条件显示：

```text
声望 0/2 或草稿 4/4
方法论笔记 2/3 或论文碎片 1/2
```

为了避免中间列过长，条件不再放进第二列。第二列只负责状态，具体条件放进详情开头。

## 已覆盖条件

当前事件选项使用的条件全部接入：

| 条件 ID | 显示 |
| --- | --- |
| `has_1_reputation` | `声望 x/1` |
| `has_2_draft` | `草稿 x/2` |
| `has_2_inspiration` | `灵感 x/2` |
| `has_2_reputation` | `声望 x/2` |
| `has_3_methodology_notes` | `方法论笔记 x/3` |
| `has_2_paper_fragments` | `论文碎片 x/2` |
| `has_4_draft` | `草稿 x/4` |
| `has_2_reputation_or_4_draft` | `声望 x/2 或草稿 y/4` |
| `has_3_methodology_notes_or_2_paper_fragments` | `方法论笔记 x/3 或论文碎片 y/2` |
| `has_2_funds` | `经费 x/2` |

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - `_populate_route_detail_event_rows()` 的事件行第二列改为只显示 `可选` / `暂不可选`。
  - `_get_event_choice_requirement_label()` 改为返回当前资源进度。
  - 新增 `_format_resource_requirement()`。
  - 新增 `_format_alternative_resource_requirement()`。
  - `_format_transfer_requirement_progress()` 复用通用二选一资源格式化。

未改变：

- 事件选项的实际可用条件不变。
- 点击事件选项后的效果不变。
- `E005 转博申请` 的资格行仍保留，且显示与提交选项保持一致。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/run/route_state.gd=0
```

`E008 导师临时约谈` 初始状态验证：

```text
带着提纲过去 | 暂不可选 | 草稿 0/2；...
顺便申请资源 | 暂不可选 | 声望 0/1；...
```

`E008` 资源满足后验证：

```text
带着提纲过去 | 可选 | 草稿 2/2；...
顺便申请资源 | 可选 | 声望 1/1；...
```

`E006 基金申请窗口` 二选一条件验证：

```text
冲刺青年基金 | 暂不可选 | 方法论笔记 2/3 或论文碎片 1/2；...
冲刺青年基金 | 可选 | 方法论笔记 2/3 或论文碎片 2/2；...
```

`E005 转博申请` 验证：

```text
转博资格 | 未满足 | 声望 0/2 或草稿 0/4，继续积累声望或草稿。
提交转博申请 | 暂不可选 | 声望 0/2 或草稿 0/4；...
转博资格 | 已满足 | 声望 0/2 或草稿 4/4，可提交转博申请。
提交转博申请 | 可选 | 声望 0/2 或草稿 4/4；...
```

## 下一步

1. 可以把同一套条件进度也接到事件按钮 tooltip 或按钮正文上。
2. 可以为已满足条件增加轻量视觉强调，例如绿色小点或更亮的状态色。
3. 可以整理事件选项 preview，减少“需要 x 资源”和进度文本之间的重复。
