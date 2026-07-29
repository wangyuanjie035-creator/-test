# 路线详情结构化行 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [022_branching_route_choice.md](022_branching_route_choice.md)
- [079_route_node_detail_panel.md](079_route_node_detail_panel.md)

## 目标

把 [079](079_route_node_detail_panel.md) 中详情面板的长段预览文字改成更易扫描的行 UI。玩家现在可以按行查看奖励卡、事件选项和 Boss 检查，而不是在一整段文字里找重点。

## UI 规则

详情面板顶部继续显示：

```text
节点名 · 节点 ID
类型：节点类型 | 风险：风险标签 | 倾向：奖励倾向
节点描述
```

下方预览区改为 `VBoxContainer` 行列表。

每一行由最多 3 个区域组成：

| 区域 | 用途 |
| --- | --- |
| 名称 | 卡牌名、事件选项名、Boss 意图名或检查项 |
| 数值 | 费用、压力、条件状态或目标值 |
| 详情 | 卡牌效果、选项结果、Boss 条件或规则说明 |

## 三类节点行

普通战斗节点：

- 第 1 行显示敌方意图。
- 后续行逐张显示可能奖励卡。
- 奖励行显示卡牌名、费用和描述。

事件节点：

- 每个事件选项一行。
- 数值区显示 `可选/暂不可选` 和条件。
- 不可选项使用更弱的颜色，方便区分。

Boss 节点：

- 显示目标进度。
- 每条被动规则一行。
- 每个 Boss 意图一行，包含压力/类型和条件。
- 阶段检查和结算资源单独成行。

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `route_detail_row_container`。
  - `get_route_detail_text()` 会收集结构化行文本，保留自动验证能力。
  - `_refresh_route_detail()` 改为设置预览标题并填充行容器。
  - 新增 `_populate_route_detail_encounter_rows()`。
  - 新增 `_populate_route_detail_event_rows()`。
  - 新增 `_populate_route_detail_boss_rows()`。
  - 新增 `_add_route_detail_row()` 和 `_collect_route_detail_row_texts()`。
  - 扩展 Boss 条件中文映射，避免详情中露出内部 condition ID。

未改变：

- 路线候选按钮正文不变。
- 点击候选进入下一节点的逻辑不变。
- 详情面板仍只读数据，不修改战斗状态。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`
- 测试存档：`user://codex_route_detail_rows_test_save.json`

脚本编译验证：

```text
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/run/route_state.gd=0
```

固定 seed 验证：

```text
option_ids=N009,E008,N003
detail_visible=true
```

普通战斗行验证：

```text
n009_row_count=6
n009_text=数据清洗夜  ·  N009|类型：战斗节点 | 风险：标准 | 倾向：数据 / 复现|原始数据里混着缺失值、异常点和记录错位。它不一定最危险，但会逼你把复现流程补上。|可能奖励|意图 | 压力 6 | 返工校验：造成 6 压力|复现实验 | 1费 | 获得 4 进度；若上回合打过实验牌，获得 1 数据。|清理实验台 | 1费 | 获得 8 防护；移除手牌中 1 张实验噪音负面牌。|负结果也是结果 | 1费 | 若手牌有实验噪音负面牌，移除 1 张，获得 1 数据和 1 灵感。|设备维护记录 | 1费 | 获得 4 防护；若有经费，消耗 1 经费，获得 1 数据和 1 方法论笔记。|研究问题清单 | 1费 | 若有灵感，抽 1 张牌；获得 1 灵感和 1 方法论笔记。
```

事件行验证：

```text
e008_row_count=4
e008_text=导师临时约谈  ·  E008|类型：事件节点 | 风险：导师变数 | 倾向：导师 / 方向|导师突然发消息说“来办公室聊一下”。这可能是方向校准、资源窗口，也可能只是一次压力同步。|选项预览|对齐阶段预期 | 可选 / 无条件 | 失去 2 精力，获得 1 方法论笔记和 1 声望。|带着提纲过去 | 暂不可选 / 需草稿 2 | 消耗 2 草稿，获得 1 论文碎片，将 1 张会后纪要加入牌组。|顺便申请资源 | 暂不可选 / 需声望 1 | 获得 1 经费，将 1 张导师沟通加入牌组。|先把压力记下来 | 可选 / 无条件 | 失去 2 精力，获得 2 经验教训，将 1 张自我怀疑加入牌组。
```

Boss 行验证：

```text
b002_row_count=10
b002_text=中期考核  ·  B002|类型：Boss 节点 | 风险：考核 | 倾向：材料 / 复现|阶段 Boss：目标进度 95。|Boss 检查|目标进度 | 95 | 阶段 Boss|规则 | 开局将 1 张恍惚加入弃牌堆。|规则 | 进度达到 50 时进行一次专家组建议检查。|汇报进展 | 压力 8 | 压力|数据真实性检查 | 检查 | 检查；持有数据|时间表追问 | 压力 10 | 压力；持有 2 草稿|横向比较 | 压力 6 | 干扰|阶段材料抽查 | 检查 | 检查；本战累计 2 数据且 3 草稿|阶段检查 | 进度 50 | 本战累计 2 数据或 3 草稿|结算资源 | 方法论笔记、论文碎片
```

## 下一步

1. 后续可以给详情行增加更明确的视觉分组，例如奖励行、选项行、Boss 行使用不同的小图标或色条。
2. 事件选项当前资源满足度已显示为具体进度，见 [082_event_requirement_progress.md](082_event_requirement_progress.md)。
3. `E005 转博申请` 的条件满足度已接进详情行，见 [081_transfer_branch_requirements.md](081_transfer_branch_requirements.md)；后续可以把事件条件进度继续接到按钮正文或 tooltip。
