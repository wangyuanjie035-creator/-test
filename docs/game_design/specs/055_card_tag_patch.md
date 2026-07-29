# 卡牌安全补标签实现 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-01

关联文档：

- [001_mvp_card_set.md](001_mvp_card_set.md)
- [004_godot_data_model.md](004_godot_data_model.md)
- [053_build_archetype_framework.md](053_build_archetype_framework.md)
- [054_card_tag_audit.md](054_card_tag_audit.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)

## 目标

按 [054_card_tag_audit.md](054_card_tag_audit.md) 的安全清单，给现有卡牌补充构筑识别标签。

本次只改 `tags`，不改：

- 卡牌费用。
- 卡牌效果。
- 卡牌描述。
- 奖励池规则。
- 路线或结算逻辑。

## 修改清单

| 卡牌 | 文件 | 修改前 | 修改后 | 目的 |
| --- | --- | --- | --- | --- |
| `C007 润色摘要` | `data/cards/reward/c007_polish_abstract.tres` | `draft`, `reputation` | `draft`, `reputation`, `paper` | 进入文献论文流检索 |
| `C020 自我调整` | `data/cards/base/c020_self_regulate.tres` | `care`, `block` | `care`, `block`, `resilience` | 明确心态照护流 |
| `C021 走出实验楼` | `data/cards/reward/c021_leave_lab.tres` | `care` | `care`, `resilience` | 明确心态照护流 |
| `C023 请教师兄` | `data/cards/base/c023_ask_senior.tres` | `network`, `discover` | `network`, `discover`, `cooperation` | 进入合作/人脉识别 |
| `C032 委员会沟通` | `data/cards/reward/c032_committee_alignment.tres` | `doctor`, `network`, `reputation` | `doctor`, `network`, `reputation`, `cooperation` | 博士线合作牌识别 |
| `U001 自我照护` | `data/cards/unlock/u001_self_care_seed.tres` | `care` | `care`, `resilience` | 局外带入服务心态照护流 |
| `U002 返修策略` | `data/cards/unlock/u002_revision_strategy_seed.tres` | `paper`, `draft` | `paper`, `draft`, `revision` | 局外带入服务返修延毕流 |
| `S001 拖延` | `data/cards/status/s001_delay.tres` | `status` | `status`, `delay` | 延毕/DDL 压力基础状态 |

## 设计影响

这些标签为后续系统提供识别基础：

- `paper`：让早期论文成果牌能被论文流检索或加成。
- `resilience`：让照护牌不只表示恢复，也能成为心态流构筑核心。
- `cooperation`：把人脉牌和合作牌区分出来，便于后续导师/合作奖励池使用。
- `revision`：让返修相关局外卡能被延毕流识别。
- `delay`：为拖延、延毕和 DDL 后遗症建立最小状态标签。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

验证输出：

```text
compile_success=true
run_success=true
card_resource_count=24
load_error_count=0
patched_tag_lines=C020:care,block,resilience|C023:network,discover,cooperation|C007:draft,reputation,paper|C021:care,resilience|C032:doctor,network,reputation,cooperation|S001:status,delay|U001:care,resilience|U002:paper,draft,revision
mismatch_count=0
```

结果说明：

- 当前 24 张卡牌资源都能被 Godot 正常加载。
- 8 张目标卡牌都读取到了新增标签。
- 没有标签缺失。
- 本次没有触及卡牌效果，因此不需要重新平衡数值。

## 下一步

1. 新增第一批流派卡，优先补 `equipment`、`mentor` 和 `rush` 三个当前空标签。
2. 更新奖励池，让新增流派卡能在普通节点或博士节点中出现。
3. “根据已有标签提高同流派奖励出现率”的轻量权重系统已完成，见 [063_weighted_reward_selection.md](063_weighted_reward_selection.md)。
