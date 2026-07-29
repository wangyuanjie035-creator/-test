# 研究生 Roguelite 构筑游戏设计文档

本文档目录用于沉淀这款游戏从策划到实现的全部设计依据。后续每个系统、原型、改动和问题都应尽量回填到对应文档，方便回溯和排查。

## 当前定位

一款以研究生从入学到毕业为过程的像素风 Roguelite 卡牌构筑游戏。玩家在每一局中经历研一、研二、研三、博一、博二、博三等阶段，通过导师、实验室、研究方向、设备、论文、合作与心理状态构筑自己的研究生路线。结局可以是正常毕业、优秀毕业、延毕毕业、转行、休学或其他坏结局，但每一局都会留下经验、资源或能力，为下一次开局提供正反馈。

## 文档地图

| 文档 | 用途 |
| --- | --- |
| [00_project_charter.md](00_project_charter.md) | 项目愿景、设计支柱、目标体验和范围边界 |
| [01_core_loop.md](01_core_loop.md) | 核心循环、资源、阶段推进、地图节点和失败状态 |
| [02_card_and_build_framework.md](02_card_and_build_framework.md) | 卡牌类型、关键词、构筑流派和卡组规则 |
| [03_meta_progression_and_legacy.md](03_meta_progression_and_legacy.md) | 局外成长、坏结局奖励、师门传承和解锁规则 |
| [04_content_backlog.md](04_content_backlog.md) | 卡牌、事件、Boss、遗物、状态和结局内容池 |
| [05_production_plan.md](05_production_plan.md) | 开发阶段、里程碑、验证方式和文档工作流 |
| [DECISIONS.md](DECISIONS.md) | 关键设计与技术决策记录 |
| [specs/README.md](specs/README.md) | 已进入纸面测试和实现准备的 MVP 规格 |
| [templates/feature_spec_template.md](templates/feature_spec_template.md) | 后续每个功能的规格模板 |

## 文档工作流

1. 先写清楚玩法目的和玩家体验。
2. 再写系统规则、数据字段和边界情况。
3. 实现前创建或更新一个功能规格文档。
4. 实现后补充验证结果、已知问题和下一步。
5. 重大取舍写入 `DECISIONS.md`，避免之后反复争论同一个问题。

## 下一步建议

先做一个纸面可玩的最小闭环：开局身份、导师、研究方向、二十到三十张基础卡、三个阶段 Boss、一次坏结局结算和一次局外解锁。确认核心循环好玩后，再进入 Godot 原型。
# 当前设计基线

已确认的当前核心机制 GDD：

- `DUAL_TOPIC_GDD_V4.md` — 《博三之前》双课题决策原型 0.2 的唯一设计基线。

`VISION_RESTORE_GDD_V3.md`、`LAB_ENGINE_GDD.md`、`RESEARCH_CHAIN_GDD.md` 与编号规格保留为历史记录或可复用实现参考；若与当前 GDD 冲突，以 `DUAL_TOPIC_GDD_V4.md` 为准。
