# 转博分支条件可视化 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-03

关联文档：

- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [034_transfer_application_event.md](034_transfer_application_event.md)
- [079_route_node_detail_panel.md](079_route_node_detail_panel.md)
- [080_route_detail_structured_rows.md](080_route_detail_structured_rows.md)

## 目标

把 `E005 转博申请` 的资格条件从“选项置灰时才知道”提前到路线详情面板里。

玩家在看到 `转博申请` 候选时，悬停或聚焦路线卡片即可知道：

- 当前是否满足转博资格。
- 声望与草稿分别积累到多少。
- 满足后提交转博会进入博士线，不提交仍进入硕士毕业线。

## 当前规则

首版转博资格：

```text
声望 >= 2
或
草稿 >= 4
```

当前仍保留初期原型的宽松入口：

- `B002 中期考核` 后，`E005 转博申请` 仍可以作为候选出现。
- 不满足资格时，`提交转博申请` 置灰，不允许进入博士线。
- 不满足资格或主动放弃时，可以选择 `先完成硕士毕业`，进入 `B003 盲审专家`。

后续正式版可以把“E005 是否出现”也改成条件触发，例如要求中期评价、导师关系、论文碎片或研究方向稳定度达标。本版本先把可读性和分支行为跑通。

## 详情行规则

当路线详情面板显示 `E005 转博申请` 时，事件选项前新增一行：

```text
转博资格 | 未满足 | 声望 0/2 或草稿 0/4，继续积累声望或草稿。
```

满足条件时显示：

```text
转博资格 | 已满足 | 声望 0/2 或草稿 4/4，可提交转博申请。
```

或：

```text
转博资格 | 已满足 | 声望 2/2 或草稿 0/4，可提交转博申请。
```

事件选项仍显示原有可选状态：

- `提交转博申请 | 可选 / 需声望 2 或草稿 4`
- `提交转博申请 | 暂不可选 / 需声望 2 或草稿 4`
- `先完成硕士毕业 | 可选 / 无条件`

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `TRANSFER_REQUIREMENT_REPUTATION = 2`。
  - 新增 `TRANSFER_REQUIREMENT_DRAFT = 4`。
  - 新增 `_is_transfer_requirement_met()`。
  - 新增 `_format_transfer_requirement_status()`。
  - 新增 `_format_transfer_requirement_detail()`。
  - 新增 `_format_transfer_requirement_progress()`。
  - `_populate_route_detail_event_rows()` 在 `E005` 事件选项前插入 `转博资格` 行。

未改变：

- `E005` 的选项数据不变。
- 提交转博后的路线仍为 `N005 博一开题重构`。
- 不转博后的路线仍为 `B003 盲审专家`。
- 条件不足时仍不会卡死，可以留在 E005 或选择硕士毕业线。

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

未满足资格详情验证：

```text
转博资格 | 未满足 | 声望 0/2 或草稿 0/4，继续积累声望或草稿。
提交转博申请 | 暂不可选 / 需声望 2 或草稿 4
```

草稿满足详情验证：

```text
转博资格 | 已满足 | 声望 0/2 或草稿 4/4，可提交转博申请。
提交转博申请 | 可选 / 需声望 2 或草稿 4
```

声望满足详情验证：

```text
转博资格 | 已满足 | 声望 2/2 或草稿 0/4，可提交转博申请。
提交转博申请 | 可选 / 需声望 2 或草稿 4
```

分支跳转验证：

```text
submit_result=true
submit_current_node=N005
master_result=true
master_current_node=B003
blocked_result=false
blocked_current_node=E005
```

## 下一步

1. 所有事件需求已升级为具体进度显示，见 [082_event_requirement_progress.md](082_event_requirement_progress.md)。
2. 可以在路线候选卡片正文上直接显示 `转博资格：未满足`，让玩家不用展开详情也能知道风险。
3. 后续正式版再把 `E005` 的出现本身改成条件触发，并为未触发时保留硕士毕业线。
