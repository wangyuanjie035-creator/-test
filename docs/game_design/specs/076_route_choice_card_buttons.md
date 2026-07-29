# 路线候选卡片按钮 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [074_route_choice_weighting.md](074_route_choice_weighting.md)
- [075_route_choice_recommendation_tooltip.md](075_route_choice_recommendation_tooltip.md)
- [077_early_route_new_nodes.md](077_early_route_new_nodes.md)
- [078_route_node_hint_data_table.md](078_route_node_hint_data_table.md)
- [079_route_node_detail_panel.md](079_route_node_detail_panel.md)

## 目标

把下一节点候选从普通文字按钮升级为更清晰的节点卡片按钮。玩家不用悬停也能看到节点类型、风险和奖励倾向；悬停时再查看推荐原因和完整说明。

## 显示规则

每个候选按钮固定为 4 行：

```text
节点名
节点类型 | 风险：风险标签
倾向：奖励倾向
目标摘要
```

示例：

```text
设备排队
战斗节点 | 风险：稳健
倾向：实验 / 设备
目标 34 / 压力 5
```

## 风险标签

- 战斗节点：
  - 每回合压力 >= 8 或目标进度 >= 44：`高压`
  - 每回合压力 <= 5 且目标进度 <= 36：`稳健`
  - 其他：`标准`
- 事件节点：优先读取路线提示资源里的 `risk_label`；缺失时显示 `变数`。
- Boss 节点：显示 `考核`。

## 奖励倾向

首版使用节点 ID 到倾向文案的映射。当前已迁移到 `data/route_node_hints/*.tres` 的 `reward_tendency` 字段，例如：

- `N003 设备排队`：`实验 / 设备`
- `E004 论文被拒`：`论文 / 心态`
- `N009 数据清洗夜`：`数据 / 复现`
- `E008 导师临时约谈`：`导师 / 方向`
- `B002 中期考核`：`材料 / 复现`
- `E005 转博申请`：`转博分支`

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - `_refresh_route_choices()` 改为调用 `_create_next_node_option_button()`。
  - 新增 `_create_next_node_option_button()`。
  - `_format_next_node_option_text()` 改为卡片四行文案。
  - 新增 `_get_next_node_type_label()`。
  - 新增 `_get_next_node_risk_label()`；当前优先读取路线提示资源。
  - 新增 `_get_next_node_reward_tendency()`；当前读取路线提示资源。
  - 新增 `_apply_next_node_option_button_style()`。
  - 新增 `_create_next_node_option_button_style()`。
  - 新增 `_get_next_node_option_accent_color()`；当前读取路线提示资源。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`
- 测试存档：`user://codex_route_card_test_save.json`

脚本编译验证：

```text
res://scripts/run/route_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
```

节点卡片按钮验证：

```text
button_count=3
first_button_size=(220.0, 132.0)
first_button_text=设备排队|战斗节点 | 风险：稳健|倾向：实验 / 设备|目标 34 / 压力 5
first_tooltip=核心设备档期有限，必须趁窗口期推进实验。压力偏低，但容易让实验流派感到节奏紧。|目标进度 34，每回合压力 5。|推荐：已有实验、设备或数据相关牌
normal_style_class=StyleBoxFlat
```

结果说明：

- 下一节点候选按钮数量正常。
- 按钮尺寸稳定，能容纳 4 行节点信息。
- 按钮正文显示节点类型、风险和奖励倾向。
- tooltip 继续显示完整说明和推荐原因。
- 按钮使用 `StyleBoxFlat` 做卡片化边框与状态样式。

## 下一步

1. 新增早期普通/事件节点已完成，见 [077_early_route_new_nodes.md](077_early_route_new_nodes.md)。
2. 风险标签、奖励倾向、强调色、路线权重和推荐原因已合并到数据表，见 [078_route_node_hint_data_table.md](078_route_node_hint_data_table.md)。
3. 如果开始做正式视觉版路线地图，可以把这些卡片作为节点详情面板的原型。
