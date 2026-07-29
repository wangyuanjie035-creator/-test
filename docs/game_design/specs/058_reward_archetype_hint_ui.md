# 奖励按钮流派提示 UI v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-01

关联文档：

- [010_reward_selection.md](010_reward_selection.md)
- [053_build_archetype_framework.md](053_build_archetype_framework.md)
- [055_card_tag_patch.md](055_card_tag_patch.md)
- [056_first_archetype_cards.md](056_first_archetype_cards.md)
- [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)
- [059_experiment_noise_cards.md](059_experiment_noise_cards.md)
- [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)
- [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)
- [064_reward_recommendation_tooltip.md](064_reward_recommendation_tooltip.md)
- [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)
- [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)
- [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)

## 目标

让玩家在奖励三选一时，不只看到卡牌效果，还能直接看到这张卡偏向哪个构筑流派。

首版按钮格式：

```text
卡名
费用 X
流派：导师人脉
效果描述
```

tooltip 中补充：

```text
效果描述
流派：导师人脉
推荐：已有导师相关牌
标签：导师、人脉、合作、经费
```

## 流派识别规则

| 标签 | 显示流派 |
| --- | --- |
| `revision`, `delay` | 返修延毕 |
| `project` | 项目经费 |
| `mentor`, `network`, `cooperation` | 导师人脉 |
| `equipment`, `experiment`, `replication`, `data` | 实验设备 |
| `rush` | DDL 爆发 |
| `care`, `resilience` | 心态照护 |
| `literature`, `paper`, `draft`, `inspiration` | 文献论文 |
| `doctor` 且没有其他流派 | 博士线 |

最多显示 2 个流派，避免按钮变得太长。

`rush` 牌不会因为带 `draft` 而额外显示 `文献论文`，例如 `通宵赶稿` 只显示 `DDL 爆发`。

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - 奖励按钮高度从 `180x120` 调整为 `200x150`。
  - 新增 `_format_reward_card_button_text()`。
  - 新增 `_format_reward_card_tooltip()`。
  - 新增 `_format_card_archetype_hint()`。
  - 新增 `_format_card_tag_hint()` 和 `_get_card_tag_display_name()`。
  - 普通、博士线和返修线的卡牌奖励按钮都会显示流派提示。
  - 后续 [064_reward_recommendation_tooltip.md](064_reward_recommendation_tooltip.md) 已在普通大候选池 tooltip 中增加推荐原因。

Boss 结局选择和 Boss 专属奖励暂不套用本规则，因为它们不是卡牌三选一，而是阶段结局或专属 reward id。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/ui/battle_test_scene.gd=0
```

奖励按钮文本验证：

```text
N002:导师沟通/费用 1/流派：导师人脉/获得 6 进度和 1 经费；移除手牌中 1 张自我怀疑。
N002:会后纪要/费用 1/流派：导师人脉/获得 1 方法论笔记和 4 防护；若有声望，抽 1 张牌。
N001:研究问题清单/费用 1/流派：文献论文/若有灵感，抽 1 张牌；获得 1 灵感和 1 方法论笔记。
N003:预约设备/费用 1/流派：实验设备/下回合第一张实验牌额外获得 8 进度。
N003:清理实验台/费用 1/流派：实验设备/获得 8 防护；移除手牌中 1 张实验噪音负面牌。
N003:负结果也是结果/费用 1/流派：实验设备 / 心态照护/若手牌有实验噪音负面牌，移除 1 张，获得 1 数据和 1 灵感。
N003:设备维护记录/费用 1/流派：实验设备/获得 4 防护；若有经费，消耗 1 经费，获得 1 数据和 1 方法论笔记。
N004:通宵赶稿/费用 0/流派：DDL 爆发/失去 4 精力，获得 2 草稿和 8 进度；将 1 张恍惚加入牌组。
N004:截稿后复盘/费用 1/流派：DDL 爆发 / 心态照护/获得 5 防护；移除牌组中 1 张负面牌；若有 2 草稿，获得 1 论文碎片。
N006:项目台账/费用 1/流派：项目经费/获得 1 方法论笔记和 4 防护；若有至少 2 经费，获得 1 论文碎片。
N008:返修清单/费用 1/流派：返修延毕 / 文献论文/移除手牌中 1 张拖延；获得 4 进度、1 草稿和 1 方法论笔记。
```

tooltip 验证：

```text
导师沟通：流派：导师人脉；标签：导师、人脉、合作、经费
会后纪要：流派：导师人脉；标签：导师、合作、方法论
研究问题清单：流派：文献论文；标签：文献、灵感、方法论
经费申请：流派：项目经费；标签：项目、经费、风险
返修清单：流派：返修延毕 / 文献论文；标签：返修、论文、延毕/拖延、方法论
清理实验台：流派：实验设备；标签：实验、防护
负结果也是结果：流派：实验设备 / 心态照护；标签：数据、方法论、心理韧性
设备维护记录：流派：实验设备；标签：设备、经费、方法论、数据
负结果也是结果：推荐：牌组已有实验噪音，可转化为数据和灵感
设备维护记录：推荐：当前有经费，可触发资源转化；已有经费相关牌
截稿后复盘：流派：DDL 爆发 / 心态照护；推荐：已有冲刺、草稿相关牌；标签：冲刺、照护、论文、草稿
```

## 下一步

1. 奖励按钮可以继续做成更清晰的视觉结构，例如流派小标签、费用徽标和效果正文分区。
2. 实验负面处理卡已完成，见 [059_experiment_noise_cards.md](059_experiment_noise_cards.md)。
3. `负结果也是结果` 的流派提示已验证，见 [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)。
4. `设备维护记录` 的流派提示已验证，见 [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)。
5. 同流派奖励权重已完成，见 [063_weighted_reward_selection.md](063_weighted_reward_selection.md)。
6. 奖励推荐原因 tooltip 已完成，见 [064_reward_recommendation_tooltip.md](064_reward_recommendation_tooltip.md)。
7. `会后纪要` 的流派和推荐原因提示已验证，见 [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)。
8. `研究问题清单` 的流派和推荐原因提示已验证，见 [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)。
9. `截稿后复盘` 的流派和推荐原因提示已验证，见 [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)。
