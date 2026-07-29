# B002 专属奖励池 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [027_boss_reward_visuals.md](027_boss_reward_visuals.md)
- [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md)
- [029_b002_material_checklist.md](029_b002_material_checklist.md)
- [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)
- [032_third_boss_blind_review.md](032_third_boss_blind_review.md)
- [034_transfer_application_event.md](034_transfer_application_event.md)

## 目标

`B002 中期考核` 不再复用 B001 的 Boss 奖励 ID，而是拥有自己的专属三选一。

设计目标：

- 奖励主题围绕中期考核：材料归档、实验复现、实验噪音清理。
- 至少一项奖励能直接改变牌组。
- B001 原奖励池不回归。

## 奖励池

| 奖励 ID | 名称 | 类型 | 效果 |
| --- | --- | --- | --- |
| `b002_archive_materials` | 归档材料清单 | 局外资源 | 方法论笔记 +1，论文碎片 +1 |
| `b002_replication_protocol` | 建立复现实验流程 | 牌组构筑 | 获得 1 张 `C013 复现实验` |
| `b002_cleanup_noise` | 清理实验噪音 | 牌组净化 | 优先移除 `S005 恍惚`、`S002 焦虑` 或 `S001 拖延` |

如果清理实验噪音时没有可移除的指定负面牌，则改为方法论笔记 +1。

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 B002 奖励 ID 常量。
  - `_prepare_reward_options()` 改为按当前 Boss 返回奖励池。
  - 新增 `_get_current_boss_reward_options()`。
  - `B002_REWARD_REPLICATION_PROTOCOL` 会调用 `battle.add_card_to_deck("C013")`。
  - `B002_REWARD_CLEANUP_NOISE` 使用 B002 专属负面牌候选。
  - Boss 奖励按钮、提示和边框颜色支持 B002 新 ID。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
battle_test_scene=0
```

B001 不回归验证：

```text
b001_options=boss_direction,boss_feedback,boss_remove_status
b001_title=开题报告通过
b001_buttons=3
```

B002 奖励池验证：

```text
b002_options=b002_archive_materials,b002_replication_protocol,b002_cleanup_noise
b002_title=中期考核通过
b002_texts=归档材料清单/局外资源/方法论笔记 +1，论文碎片 +1|建立复现实验流程/牌组构筑/获得 1 张复现实验|清理实验噪音/牌组净化/移除 1 张恍惚或焦虑或拖延
b002_buttons=3
selected_protocol=true
protocol_result=建立复现实验流程：获得 复现实验。
has_c013=true
deck_delta=1
settlement_after_b002=false
options_after_b002=B003,E005
```

其他分支验证：

```text
archive_selected=true
archive_result=归档材料清单：方法论笔记 +1，论文碎片 +1。
archive_methodology=1
archive_paper=1
cleanup_has_s005_before=true
cleanup_selected=true
cleanup_result=删除负面牌：移除 恍惚。
cleanup_has_s005_after=false
cleanup_next_option=B003,E005
```

## 结果说明

- B002 已拥有独立奖励池。
- B001 原奖励池保持不变。
- B002 奖励能提供局外资源、实验牌和负面清理三类选择。
- B002 奖励选择后会正常进入下一节点候选 `B003` 和 `E005`。

## 下一步

1. B002 后转博/不转博分支锚点已记录，见 [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md)。
2. `B003 盲审专家` 已完成首版实现，见 [032_third_boss_blind_review.md](032_third_boss_blind_review.md)。
3. `E005 转博申请` 已完成首版接入，见 [034_transfer_application_event.md](034_transfer_application_event.md)。
4. 后续可把 Boss 奖励池移动到数据资源，而不是写在 UI 脚本中。
