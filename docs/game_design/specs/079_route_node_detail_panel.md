# 路线节点详情面板 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [076_route_choice_card_buttons.md](076_route_choice_card_buttons.md)
- [078_route_node_hint_data_table.md](078_route_node_hint_data_table.md)
- [080_route_detail_structured_rows.md](080_route_detail_structured_rows.md)

## 目标

在玩家选择下一节点前，给出更完整的风险、奖励和事件选项预览。路线候选按钮继续保持 4 行摘要；新增详情面板负责展示更长的信息，避免按钮本身变得拥挤。

## UI 规则

- 当出现下一节点候选时，候选按钮下方显示路线节点详情面板。
- 面板默认展示第一个候选节点。
- 鼠标悬停或键盘焦点进入某个候选按钮时，面板切换到该节点。
- 鼠标移出当前候选按钮后，面板回到第一个候选节点。
- 没有候选、路线未完成当前节点或进入结算时，面板隐藏。

## 显示内容

所有节点都显示：

```text
节点名 · 节点 ID
类型：节点类型 | 风险：风险标签 | 倾向：奖励倾向
```

普通战斗节点额外显示：

- 节点描述
- 敌方意图
- 可能奖励卡牌名称

事件节点额外显示：

- 事件描述
- 选项预览
- 每个选项的可用状态、条件和结果预览

Boss 节点额外显示：

- 目标进度
- 被动规则
- 意图循环
- 阶段检查条件
- 结算资源

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `route_detail_panel`、标题、元信息、描述和预览标签。
  - 新增 `get_route_detail_visible()` 和 `get_route_detail_text()` 验证接口。
  - 下一节点按钮新增 `mouse_entered`、`mouse_exited` 和 `focus_entered` 信号。
  - 新增 `_refresh_route_detail()` 和 `_clear_route_detail()`。
  - 新增 `_format_route_detail_description()` 和 `_format_route_detail_preview()`。
  - 新增事件条件、Boss 阶段条件、奖励卡名和资源名格式化辅助函数。

未改变：

- 下一节点点击选择逻辑不变。
- 路线权重、候选抽取和按钮正文不变。
- 详情面板只读当前节点数据，不写入战斗或路线状态。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`
- 测试存档：`user://codex_route_detail_test_save.json`

脚本编译验证：

```text
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/run/route_state.gd=0
```

固定 seed 路线详情验证：

```text
option_ids=N009,E008,N003
button_count=3
detail_visible=true
```

默认详情验证：

```text
detail_default=数据清洗夜  ·  N009|类型：战斗节点 | 风险：标准 | 倾向：数据 / 复现|原始数据里混着缺失值、异常点和记录错位。它不一定最危险，但会逼你把复现流程补上。|意图：返工校验：造成 6 压力。|可能奖励：复现实验、清理实验台、负结果也是结果、设备维护记录、研究问题清单
```

事件候选悬停验证：

```text
detail_e008=导师临时约谈  ·  E008|类型：事件节点 | 风险：导师变数 | 倾向：导师 / 方向|导师突然发消息说“来办公室聊一下”。这可能是方向校准、资源窗口，也可能只是一次压力同步。|选项预览：|- 对齐阶段预期（可选，无条件）：失去 2 精力，获得 1 方法论笔记和 1 声望。|- 带着提纲过去（暂不可选，需草稿 2）：消耗 2 草稿，获得 1 论文碎片，将 1 张会后纪要加入牌组。|- 顺便申请资源（暂不可选，需声望 1）：获得 1 经费，将 1 张导师沟通加入牌组。|- 先把压力记下来（可选，无条件）：失去 2 精力，获得 2 经验教训，将 1 张自我怀疑加入牌组。
detail_after_unhover=数据清洗夜  ·  N009|类型：战斗节点 | 风险：标准 | 倾向：数据 / 复现|原始数据里混着缺失值、异常点和记录错位。它不一定最危险，但会逼你把复现流程补上。|意图：返工校验：造成 6 压力。|可能奖励：复现实验、清理实验台、负结果也是结果、设备维护记录、研究问题清单
```

Boss 详情验证：

```text
detail_b002=中期考核  ·  B002|类型：Boss 节点 | 风险：考核 | 倾向：材料 / 复现|阶段 Boss：目标进度 95。|规则：开局将 1 张恍惚加入弃牌堆。；进度达到 50 时进行一次专家组建议检查。|意图循环：汇报进展 / 数据真实性检查 / 时间表追问 / 横向比较 / 阶段材料抽查|阶段检查：进度 50，本战累计 2 数据或 3 草稿。|结算资源：方法论笔记、论文碎片
```

## 下一步

1. 详情面板中的长文本已改成结构化行 UI，见 [080_route_detail_structured_rows.md](080_route_detail_structured_rows.md)。
2. 如果开始做正式路线地图，当前详情面板可以迁移为地图节点的详情侧栏。
3. 当转博条件正式策划化后，详情面板应提前显示 `E005 转博申请` 的关键条件和当前满足情况。
