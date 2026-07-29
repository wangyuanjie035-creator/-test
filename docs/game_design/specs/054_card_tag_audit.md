# 卡牌标签审计 v0.1

状态：设计审计，尚未修改卡牌数据

创建日期：2026-06-01

关联文档：

- [001_mvp_card_set.md](001_mvp_card_set.md)
- [004_godot_data_model.md](004_godot_data_model.md)
- [010_reward_selection.md](010_reward_selection.md)
- [053_build_archetype_framework.md](053_build_archetype_framework.md)
- [055_card_tag_patch.md](055_card_tag_patch.md)
- [056_first_archetype_cards.md](056_first_archetype_cards.md)
- [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)
- [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)
- [059_experiment_noise_cards.md](059_experiment_noise_cards.md)
- [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)
- [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)

## 目标

在正式补标签和新增流派卡之前，先审计当前已经实现的 `.tres` 卡牌：

- 每张卡当前有哪些标签。
- 每张卡更适合归入哪个构筑流派。
- 哪些标签可以安全补充。
- 哪些流派当前缺卡，需要优先新增内容。

本文件只记录审计结论，不直接改数据。实际数据修改应放到下一份实现规格中。

## 当前卡牌范围

当前已实现卡牌共 24 张：

| 类型 | 数量 | 卡牌 |
| --- | --- | --- |
| 初始牌 | 5 | `C001`, `C006`, `C011`, `C020`, `C023` |
| 普通奖励牌 | 6 | `C002`, `C004`, `C007`, `C012`, `C013`, `C021` |
| 博士奖励牌 | 5 | `C031`, `C032`, `C033`, `C034`, `C035` |
| 局外解锁牌 | 3 | `U001`, `U002`, `U003` |
| 状态牌 | 5 | `S001`, `S002`, `S004`, `S005`, `S010` |

## 总体结论

| 流派 | 当前状态 | 结论 |
| --- | --- | --- |
| 文献论文流 | 已有骨架 | 文献、草稿、论文碎片链条已经能跑，但 `paper` 标签覆盖不足 |
| 实验设备流 | 已有实验和设备骨架 | 实验、复现、预约设备和实验噪音清理已经可用 |
| 导师人脉流 | 有人脉骨架，缺导师 | `network` 已存在，`mentor` 和 `cooperation` 需要补齐 |
| 项目经费流 | 只有博士线雏形 | 当前主要依赖 `C034 项目排期表`，硕士阶段几乎没有项目卡 |
| 心态照护流 | 已有基础 | 照护和防护可用，但缺 `resilience` 这类构筑识别标签 |
| DDL 爆发流 | 尚未实现 | 当前没有 `rush`、`risk` 牌，只能靠设计规格后续新增 |
| 返修延毕流 | 局外解锁骨架清晰 | `U002/U003` 已能支撑返修方向，但 `delay` 标签尚未落地 |

## 初始牌审计

| ID | 名称 | 当前标签 | 流派定位 | 审计结论 |
| --- | --- | --- | --- | --- |
| `C001` | 查文献 | `literature` | 文献论文 | 标签准确，可保持 |
| `C006` | 写草稿 | `draft` | 文献论文、DDL 爆发 | 可保持；暂不急着加 `paper`，避免所有草稿牌都被视为论文牌 |
| `C011` | 做实验 | `experiment`, `data` | 实验设备 | 标签准确，可保持 |
| `C020` | 自我调整 | `care`, `block` | 心态照护 | 建议后续补 `resilience` |
| `C023` | 请教师兄 | `network`, `discover` | 导师人脉 | 建议后续补 `cooperation`，保持 `network` |

## 普通奖励牌审计

| ID | 名称 | 当前标签 | 流派定位 | 审计结论 |
| --- | --- | --- | --- | --- |
| `C002` | 精读文献 | `literature`, `inspiration` | 文献论文 | 标签准确，可保持 |
| `C004` | 整理笔记 | `literature`, `draft` | 文献论文 | 标签准确，可保持 |
| `C007` | 润色摘要 | `draft`, `reputation` | 文献论文、导师人脉 | 建议后续补 `paper` |
| `C012` | 样本制备 | `experiment`, `data` | 实验设备 | 标签准确，可保持 |
| `C013` | 复现实验 | `experiment`, `replication` | 实验设备 | 标签准确，可保持 |
| `C021` | 走出实验楼 | `care` | 心态照护 | 建议后续补 `resilience` |

## 博士奖励牌审计

| ID | 名称 | 当前标签 | 流派定位 | 审计结论 |
| --- | --- | --- | --- | --- |
| `C031` | 问题链重排 | `doctor`, `methodology`, `draft` | 文献论文、返修延毕 | 可保持；如果后续论文牌检索不足，再考虑补 `paper` |
| `C032` | 委员会沟通 | `doctor`, `network`, `reputation` | 导师人脉 | 建议后续补 `cooperation` |
| `C033` | 论文主线图 | `doctor`, `paper`, `draft` | 文献论文、返修延毕 | 标签准确，可保持 |
| `C034` | 项目排期表 | `doctor`, `project`, `funds`, `block` | 项目经费 | 标签准确，可保持 |
| `C035` | 预答辩演练 | `doctor`, `paper`, `reputation` | 导师人脉、文献论文 | 可保持；后续若加入答辩专属机制，再补 `defense` |

## 局外解锁牌审计

| ID | 名称 | 当前标签 | 流派定位 | 审计结论 |
| --- | --- | --- | --- | --- |
| `U001` | 自我照护 | `care` | 心态照护 | 建议后续补 `resilience` |
| `U002` | 返修策略 | `paper`, `draft` | 返修延毕、文献论文 | 建议后续补 `revision` |
| `U003` | 返修矩阵 | `paper`, `doctor`, `revision` | 返修延毕、文献论文 | 标签准确，可保持 |

## 状态牌审计

| ID | 名称 | 当前标签 | 压力来源 | 审计结论 |
| --- | --- | --- | --- | --- |
| `S001` | 拖延 | `status` | DDL 爆发、心态照护 | 建议后续补 `delay` |
| `S002` | 焦虑 | `status` | 心态照护、导师人脉 | 暂不新增标签，等状态子类统一设计 |
| `S004` | 信息过载 | `status` | 文献论文 | 暂不新增标签，避免被文献奖励池误选 |
| `S005` | 恍惚 | `status` | DDL 爆发 | 暂不新增标签，等 `rush` 牌实现后再决定 |
| `S010` | 自我怀疑 | `status` | 导师人脉、Boss 压力 | 暂不新增标签，等导师负面机制成型 |

状态牌目前只用 `status` 是安全的。后续如果要做“消耗某类负面牌换收益”，再统一设计 `delay_status`、`mental_status`、`literature_status` 之类的子类标签。

## 建议的安全补标签清单

下一步可以优先做这些低风险标签补充，不改变任何卡牌效果：

| 卡牌 | 当前标签 | 建议新增 | 理由 |
| --- | --- | --- | --- |
| `C007 润色摘要` | `draft`, `reputation` | `paper` | 它是最早的论文成果转化牌，适合进入论文流检索 |
| `C020 自我调整` | `care`, `block` | `resilience` | 让心态照护流更容易被识别 |
| `C021 走出实验楼` | `care` | `resilience` | 同上 |
| `C023 请教师兄` | `network`, `discover` | `cooperation` | 牌类型已经是合作牌，补标签一致 |
| `C032 委员会沟通` | `doctor`, `network`, `reputation` | `cooperation` | 博士线人脉牌，应被合作流识别 |
| `U001 自我照护` | `care` | `resilience` | 局外带入卡应明确服务心态照护流 |
| `U002 返修策略` | `paper`, `draft` | `revision` | 局外带入卡应明确服务返修延毕流 |
| `S001 拖延` | `status` | `delay` | 拖延是延毕/DDL 压力的基础负面状态 |

## 暂缓补标签清单

这些标签现在不建议强行补到旧卡上：

| 标签 | 暂缓原因 |
| --- | --- |
| `mentor` | 当前没有真正导师牌，`请教师兄` 和 `委员会沟通` 更适合先归为人脉/合作 |
| `equipment` | 当前没有设备牌，实验牌不等于设备牌 |
| `rush` | 当前没有 DDL 爆发牌，等 `通宵赶稿`、`极限 ddl` 接入后再使用 |
| `risk` | 当前没有风险牌，避免把普通压力牌提前风险化 |
| `delay` | 只建议先给 `S001 拖延`，延毕牌需要后续新卡承接 |
| `defense` | 预答辩和答辩可以后续单独做 Boss/阶段标签，目前不是首轮必要标签 |

## 新卡优先级

基于本次审计，下一批卡最需要补这些空位：

| 优先级 | 流派 | 建议新卡 | 目的 |
| --- | --- | --- | --- |
| 1 | 实验设备 | `预约设备`、`清理实验台`、`负结果也是结果`、`设备维护记录` | 已接入，见 [056_first_archetype_cards.md](056_first_archetype_cards.md)、[059_experiment_noise_cards.md](059_experiment_noise_cards.md)、[061_negative_result_conversion_card.md](061_negative_result_conversion_card.md) 和 [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md) |
| 2 | 导师人脉 | `导师沟通`、`组会汇报` | 已接入，`mentor` 标签开始落地 |
| 3 | DDL 爆发 | `通宵赶稿`、`极限 ddl` | 已接入，`rush`、`risk` 流派开始可玩 |
| 4 | 项目经费 | `经费申请`、`项目台账` | 已接入，见 [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md) |
| 5 | 返修延毕 | `返修清单` | 已接入，见 [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md) |

## 下一步

1. 安全补标签已完成，见 [055_card_tag_patch.md](055_card_tag_patch.md)。
2. 第一批流派卡已完成，见 [056_first_archetype_cards.md](056_first_archetype_cards.md)。
3. 项目经费流和返修延毕流已完成首批卡，见 [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)。
4. 奖励 UI 标签提示已完成，见 [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)。
5. 实验负面处理已完成，见 [059_experiment_noise_cards.md](059_experiment_noise_cards.md)。
6. 实验噪音转化已完成，见 [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)。
7. 设备维护转化已完成，见 [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)。
