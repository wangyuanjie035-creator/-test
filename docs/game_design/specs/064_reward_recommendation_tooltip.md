# 奖励推荐原因 Tooltip v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-06-02

关联文档：

- [010_reward_selection.md](010_reward_selection.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)
- [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)
- [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)
- [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)
- [068_weighted_reward_random_selection.md](068_weighted_reward_random_selection.md)

## 目标

让玩家和测试者在奖励三选一时能看懂“为什么这张卡被推上来”。首版只在普通节点候选池超过 3 张、实际发生加权裁剪时显示推荐原因。

推荐原因放在 tooltip 中，不进入按钮正文，避免奖励按钮过长。

## 显示规则

tooltip 新增一行：

```text
推荐：牌组已有实验噪音，可转化为数据和灵感
```

首版推荐原因来源：

- 牌组已有 `experiment_noise` 状态牌时：
  - `C028 负结果也是结果` 显示“牌组已有实验噪音，可转化为数据和灵感”。
  - `C014 清理实验台` 显示“牌组已有实验噪音，可清理实验风险”。
- 当前有经费且候选卡带 `funds` 标签时，显示“当前有经费，可触发资源转化”。
- 候选卡标签命中玩家牌组里的非初始卡标签时，显示“已有 X 相关牌”。
- 同一张卡最多显示 2 条推荐原因。
- 固定三选一节点、博士线固定奖励池、Boss 奖励和结局选择不显示推荐原因。

## 实现内容

更新：

- `scripts/ui/battle_test_scene.gd`
  - `_format_reward_card_tooltip()` 增加推荐原因行。
  - 新增 `_format_reward_recommendation_hint()`。
  - 新增 `_current_reward_pool_needs_weighting()`，限制只有大候选池裁剪时显示推荐原因。
  - 新增 `_format_matching_reward_tag_reason()` 和 `_append_reward_reason()`。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

脚本编译验证：

```text
res://scripts/battle/battle_state.gd=0
res://scripts/ui/battle_test_scene.gd=0
res://scripts/data/game_data_catalog.gd=0
res://scripts/data/card_definition.gd=0
res://scripts/data/effect_definition.gd=0
res://scripts/data/encounter_definition.gd=0
```

tooltip 验证：

```text
n003_noise_options=C028,C014,C012
c028_noise_tooltip=若手牌有实验噪音负面牌，移除 1 张，获得 1 数据和 1 灵感。|流派：实验设备 / 心态照护|推荐：牌组已有实验噪音，可转化为数据和灵感|标签：数据、方法论、心理韧性
c014_noise_tooltip=获得 8 防护；移除手牌中 1 张实验噪音负面牌。|流派：实验设备|推荐：牌组已有实验噪音，可清理实验风险|标签：实验、防护
n003_funds_options=C038,C012,C014
c038_funds_tooltip=获得 4 防护；若有经费，消耗 1 经费，获得 1 数据和 1 方法论笔记。|流派：实验设备|推荐：当前有经费，可触发资源转化；已有经费相关牌|标签：设备、经费、方法论、数据
c015_default_tooltip=下回合第一张实验牌额外获得 8 进度。|流派：实验设备|标签：设备、实验
n004_fixed_tooltip=失去 4 精力，获得 2 草稿和 8 进度；将 1 张恍惚加入牌组。|流派：DDL 爆发|标签：DDL 爆发、风险、草稿
```

结果说明：

- `N003` 实验噪音场景会给 `C028/C014` 显示推荐原因。
- `N003` 经费场景会给 `C038` 显示推荐原因。
- 默认无倾向的 `C015` 不显示推荐原因。
- 下方 `N004` 输出保留扩展前的固定三选一历史值；当前 `N004` 已扩展为 5 张候选池，见 [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)。

`N002` 后续已扩展为 5 张候选池，见 [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md)。
`N001` 后续已扩展为 5 张候选池，见 [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)。
`N004` 后续已扩展为 5 张候选池，见 [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)。

## 下一步

1. 后续可以把推荐原因升级为按钮上的小图标或短标签，但首版先保持 tooltip。
2. 带权随机接入后，可以继续复用这套推荐原因文本。
3. 等更多节点有 4-6 张候选池后，再观察推荐原因是否需要更口语化。
4. `N004` 的 DDL 推荐原因已验证，见 [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)。
5. 推荐原因已随带权随机继续复用，见 [068_weighted_reward_random_selection.md](068_weighted_reward_random_selection.md)。
