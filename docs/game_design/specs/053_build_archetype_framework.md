# 构筑流派框架 v0.1

状态：设计规格，准备进入首轮实现

创建日期：2026-06-01

关联文档：

- [001_mvp_card_set.md](001_mvp_card_set.md)
- [004_godot_data_model.md](004_godot_data_model.md)
- [010_reward_selection.md](010_reward_selection.md)
- [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md)
- [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md)
- [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md)
- [052_settlement_entry_rows.md](052_settlement_entry_rows.md)
- [054_card_tag_audit.md](054_card_tag_audit.md)
- [055_card_tag_patch.md](055_card_tag_patch.md)
- [056_first_archetype_cards.md](056_first_archetype_cards.md)
- [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)
- [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)
- [059_experiment_noise_cards.md](059_experiment_noise_cards.md)
- [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)
- [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)
- [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)
- [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)
- [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)

## 目标

第二阶段的重点从“路线能跑通”转向“每局有清晰构筑身份”。

玩家应该在一局中逐渐形成类似下面的判断：

- 我这局像是在走实验数据流，先攒数据，再用论文牌爆发。
- 我这局拿了很多导师和委员会沟通，适合打 Boss 条件和结局门槛。
- 我这局虽然失败了，但坏结局给的返修资源会让下一局更容易走延毕返修流。

## 设计原则

1. 每个流派都必须和研究生主题强绑定，而不是只做传统攻击、防御、抽牌换皮。
2. 每个流派都要有正反馈链条：前置投入、核心转化、后期奖励。
3. 失败也要能进入正循环：坏结局给资源、资源解锁卡、解锁卡再影响下一局构筑。
4. 流派之间不做硬隔离，标签可以重叠，奖励池允许玩家自然混搭。
5. 首轮实现优先使用现有字段：`tags`、`rarity`、`effects`、`condition`、`tag_filter`。
6. 暂不把“研究方向”做成复杂职业系统，先作为高阶方向牌或路线奖励，等基础构筑稳定后再扩。

## 当前基础

现有 `CardDefinition` 已有 `tags: PackedStringArray`，当前已使用的标签包括：

```text
literature, inspiration, draft, experiment, data, replication,
care, block, network, discover, doctor, methodology,
paper, project, funds, reputation, revision, status,
experiment_noise
```

这意味着首轮构筑实现可以先做标签审计和奖励池分层，不需要立刻重写卡牌数据模型。

## 核心流派

### 文献论文流

核心体验：用文献和笔记提供过牌、灵感和草稿，再把草稿转成论文进度、声望和论文碎片。

| 项 | 内容 |
| --- | --- |
| 主要标签 | `literature`, `inspiration`, `draft`, `paper`, `methodology` |
| 关键资源 | 灵感、草稿、论文碎片、方法论笔记 |
| 现有卡 | `C001 查文献`, `C002 精读文献`, `C004 整理笔记`, `C006 写草稿`, `C007 润色摘要`, `C031 问题链重排`, `C033 论文主线图`, `U002 返修策略`, `U003 返修矩阵` |
| 正反馈 | 文献牌过牌并产灵感，草稿牌产材料，论文牌把材料转为高进度和结局资源 |
| 风险 | 信息过载、格式错误、草稿不足时推进乏力 |

首批补充方向：

- `综述框架`：文献牌，按本战打出的文献牌数量获得进度。
- `投稿日历`：论文牌，消耗草稿，获得声望和论文碎片。
- `审稿意见归纳`：返修/论文牌，把负面状态转为方法论笔记。
- `研究问题清单`：文献/方法论牌，把早期灵感整理为方法论笔记，有灵感时额外抽牌。已接入，见 [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)。

### 实验设备流

核心体验：通过实验、样本、设备和复现机制持续产出数据，再用数据支撑论文和 Boss 材料检查。

| 项 | 内容 |
| --- | --- |
| 主要标签 | `experiment`, `data`, `replication`, `equipment`, `funds`, `experiment_noise` |
| 关键资源 | 数据、经费、方法论笔记 |
| 现有卡 | `C011 做实验`, `C012 样本制备`, `C013 复现实验`, `C014 清理实验台`, `C015 预约设备`, `C028 负结果也是结果`, `C038 设备维护记录`, `S003 不可复现`, `S009 样本污染` |
| 正反馈 | 样本制备强化下一张实验牌，实验牌产数据，复现牌根据上一回合实验继续滚资源，实验噪音可被转化为数据和灵感，经费可转化为数据和方法论 |
| 风险 | 样本污染、不可复现、设备排队、经费不足 |

首批补充方向：

- `预约设备`：设备牌，强化下一张实验牌。已接入，见 [056_first_archetype_cards.md](056_first_archetype_cards.md)。
- `清理实验台`：防护牌，移除实验相关负面状态。已接入，见 [059_experiment_noise_cards.md](059_experiment_noise_cards.md)。
- `负结果也是结果`：转化牌，把实验噪音变成数据和灵感。已接入，见 [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)。
- `设备维护记录`：设备/方法论牌，消耗经费换数据和方法论笔记。已接入，见 [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)。

### 导师人脉流

核心体验：用导师、师兄师姐、委员会和合作关系获得声望、发现牌和条件减压，让 Boss 和毕业结局更容易达标。

| 项 | 内容 |
| --- | --- |
| 主要标签 | `mentor`, `network`, `cooperation`, `reputation`, `doctor` |
| 关键资源 | 声望、经费、心理韧性 |
| 现有卡 | `C023 请教师兄`, `C032 委员会沟通`, `C035 预答辩演练` |
| 正反馈 | 人脉牌提供发现、声望和防护，声望支撑事件选项、Boss 检查和优秀结局 |
| 风险 | 自我怀疑、组会压力、成果归属不稳 |

首批补充方向：

- `导师沟通`：三选一获得进度、经费或移除自我怀疑。
- `组会汇报`：有数据时获得声望，无数据时加入自我怀疑。
- `会后纪要`：把周会反馈沉淀为方法论笔记和防护，有声望时额外抽牌。已接入，见 [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)。
- `合作邮件`：发现合作牌或论文牌，提升构筑弹性。

### 项目经费流

核心体验：通过经费、项目台账和排期，把资源管理转为稳定防护、进度和博士线材料。

| 项 | 内容 |
| --- | --- |
| 主要标签 | `project`, `funds`, `block`, `doctor`, `methodology` |
| 关键资源 | 经费、方法论笔记、论文碎片 |
| 现有卡 | `C034 项目排期表` |
| 正反馈 | 经费越多，项目牌越容易同时给防护和进度，并支撑基金事件和项目 Boss |
| 风险 | 行政杂务、经费冻结、排期失控 |

首批补充方向：

- `经费申请`：获得经费和防护，但可能加入行政杂务。
- `项目台账`：把经费或数据转为方法论笔记。
- `横向项目取舍`：高收益高压力，适合博士线中期。

### 心态照护流

核心体验：通过照护、防护和负面状态处理维持精力，把“活下来”变成稳定推进能力。

| 项 | 内容 |
| --- | --- |
| 主要标签 | `care`, `block`, `status`, `resilience` |
| 关键资源 | 心理韧性、经验教训、精力 |
| 现有卡 | `C020 自我调整`, `C021 走出实验楼`, `U001 自我照护` |
| 正反馈 | 照护牌减少坏状态影响，维持精力，延长路线并提高失败后的局外收益 |
| 风险 | 直接进度偏低，过度防守会被 Boss 阶段检查卡住 |

首批补充方向：

- `看淡一切`：消耗负面牌获得灵感，延毕阶段额外抽牌。
- `规律作息`：获得防护并减少下回合压力。
- `心理咨询预约`：恢复精力，移除焦虑或自我怀疑。

### DDL 爆发流

核心体验：用熬夜、极限 ddl 和短期爆发换取高速推进，再依靠照护或返修资源处理后遗症。

| 项 | 内容 |
| --- | --- |
| 主要标签 | `rush`, `risk`, `draft`, `paper`, `care` |
| 关键资源 | 草稿、精力、心理韧性 |
| 现有卡 | `C018 通宵赶稿`, `C019 极限 ddl`, `C041 截稿后复盘`，以及基础草稿和照护卡 |
| 正反馈 | 低费用或额外行动点制造爆发，快速通过普通节点或冲 Boss 阶段 |
| 风险 | 精力损失、恍惚、焦虑、拖延 |

首批补充方向：

- `通宵赶稿`：失去精力，获得草稿和进度，加入恍惚。
- `极限 ddl`：本回合获得行动点，本牌消耗。
- `截稿后复盘`：清理 DDL 后遗症，把草稿沉淀为论文碎片。已接入，见 [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)。
- `补觉半天`：恢复精力但本回合推进低，作为后续更纯粹的照护牌候选。

### 返修延毕流

核心体验：把失败、返修和延毕从纯惩罚变成“二周目构筑资产”，让坏结局也能成为下一局的清晰方向。

| 项 | 内容 |
| --- | --- |
| 主要标签 | `revision`, `delay`, `doctor`, `paper`, `care`, `status` |
| 关键资源 | 黑历史档案、方法论笔记、论文碎片、心理韧性 |
| 现有卡 | `U002 返修策略`, `U003 返修矩阵`, `C031 问题链重排`, `C033 论文主线图` |
| 正反馈 | 坏结局给局外资源，资源触发解锁，解锁卡在下一局提供更强的返修和论文基础 |
| 风险 | 成型依赖失败或后期路线，前期不应太强 |

首批补充方向：

- `黑历史复盘`：根据局外黑历史档案获得进度或方法论笔记。
- `返修清单`：把负面状态转为草稿或论文碎片。
- `第二次答辩演练`：延毕阶段获得额外声望和防护。

## 标签规范

首轮建议把标签分为三类：

| 类型 | 标签 | 用途 |
| --- | --- | --- |
| 主题标签 | `literature`, `experiment`, `paper`, `mentor`, `network`, `project`, `care`, `revision` | 奖励池分层和流派识别 |
| 资源标签 | `inspiration`, `data`, `draft`, `funds`, `reputation`, `methodology` | 条件、发现和卡牌协同 |
| 状态标签 | `risk`, `rush`, `block`, `status`, `delay`, `doctor`, `experiment_noise` | 副作用、阶段限定和特殊构筑 |

命名规则：

- 标签统一使用小写英文。
- 已有标签尽量保留，不做大规模重命名。
- 新增 `mentor`、`equipment`、`cooperation`、`rush`、`risk`、`delay`、`resilience` 时，先用于新卡，不强迫旧卡一次性全改。
- 若一张牌同时属于两个流派，保留两个主题标签，例如 `paper + revision`。

## 奖励池分层

首轮先采用三层池；普通节点候选池超过 3 张时，再由 [063_weighted_reward_selection.md](063_weighted_reward_selection.md) 按构筑标签裁剪为三选一：

| 奖励池 | 出现场景 | 内容倾向 |
| --- | --- | --- |
| 基础共通池 | 硕士普通节点 | 文献、实验、草稿、照护 |
| 方向倾向池 | 事件、Boss 奖励、路线节点 | 导师、人脉、项目、论文 |
| 阶段专属池 | 博士线、延毕线、坏结局解锁 | 博士、项目、答辩、返修 |

同流派奖励权重首版已经接入：候选池仍由节点主题决定，权重只负责在候选过多时把更贴合当前牌组的 3 张推到界面上。

## 正反馈链条

每个流派至少要有一条正反馈链：

| 流派 | 链条 |
| --- | --- |
| 文献论文 | 文献过牌 -> 灵感/草稿 -> 论文牌 -> 论文碎片/声望 |
| 实验设备 | 样本/设备 -> 实验进度 -> 数据 -> 复现/论文转化；实验噪音 -> 清理实验台/负结果也是结果 -> 防护、数据和灵感；经费 -> 设备维护 -> 数据和方法论 |
| 导师人脉 | 沟通/合作 -> 声望/发现 -> Boss 条件更容易达成 |
| 项目经费 | 经费 -> 项目牌强化 -> 防护/进度 -> 博士 Boss 材料 |
| 心态照护 | 防护/恢复 -> 状态清理 -> 路线存活 -> 局外资源增加 |
| DDL 爆发 | 风险牌 -> 高速推进 -> 后遗症 -> 截稿复盘/照护/返修处理 |
| 返修延毕 | 坏结局资源 -> 解锁返修卡 -> 下局更强论文基础 |

## 首轮实现建议

1. 已新增 [054_card_tag_audit.md](054_card_tag_audit.md)：梳理现有每张牌属于哪个流派、缺哪些标签。
2. 已按 [055_card_tag_patch.md](055_card_tag_patch.md) 在数据里补齐少量安全标签，不改变卡牌效果。
3. 已新增第一批设备、导师和 DDL 流派卡，见 [056_first_archetype_cards.md](056_first_archetype_cards.md)。
4. 已新增项目经费流和返修延毕流卡牌，见 [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)。
5. 奖励按钮已增加流派提示，见 [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)。
6. 实验噪音和 `清理实验台` 已接入，见 [059_experiment_noise_cards.md](059_experiment_noise_cards.md)。
7. `负结果也是结果` 已接入，见 [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md)。
8. `设备维护记录` 已接入，见 [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md)。
9. 同流派奖励权重已接入，见 [063_weighted_reward_selection.md](063_weighted_reward_selection.md)。
10. `N002` 候选池扩展和 `会后纪要` 已接入，见 [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)。
11. `N001` 候选池扩展和 `研究问题清单` 已接入，见 [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)。
12. `N004` 候选池扩展和 `截稿后复盘` 已接入，见 [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)。
13. 后续更新普通奖励池和博士奖励池时，优先使用“节点候选池 + 三选一裁剪”的方式。

## 验收标准

首轮实现完成后，应满足：

- 现有可用卡牌都能归入至少一个核心流派。
- 至少 3 个流派能在实际奖励选择中连续拿到 2 张以上相关卡。
- 新标签不会影响旧卡的加载、出牌和结算。
- 坏结局解锁卡能明确服务 `返修延毕流`，而不是只是单独的强力卡。
- 手动测试时，玩家能从奖励选择文字中判断“这张牌适合我的当前构筑”。
