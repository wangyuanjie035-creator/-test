# 普通节点候选池扩展 v0.1

状态：已完成 `N002` 首轮扩展，并通过 Godot 编辑器验证

创建日期：2026-06-02

关联文档：

- [010_reward_selection.md](010_reward_selection.md)
- [021_manual_playtest_guide.md](021_manual_playtest_guide.md)
- [053_build_archetype_framework.md](053_build_archetype_framework.md)
- [056_first_archetype_cards.md](056_first_archetype_cards.md)
- [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md)
- [063_weighted_reward_selection.md](063_weighted_reward_selection.md)
- [064_reward_recommendation_tooltip.md](064_reward_recommendation_tooltip.md)
- [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)
- [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)

## 目标

让普通节点奖励池从固定三选一逐步扩展为 4-6 张候选池，再由同流派奖励权重裁剪为三选一。

本轮先扩展 `N002 周会压力`，因为它能承接导师人脉、合作、声望、项目经费和心态照护，是实验设备流之外最适合验证第二条构筑线的节点。

## 新增卡牌

| ID | 名称 | 费用 | 标签 | 定位 | 效果 |
| --- | --- | --- | --- | --- | --- |
| `C039` | 会后纪要 | 1 | `mentor`, `cooperation`, `methodology` | 周会反馈沉淀 | 获得 1 方法论笔记和 4 防护；若有声望，抽 1 张牌 |

升级版预留效果：

- 获得 1 方法论笔记和 6 防护。
- 若有声望，抽 2 张牌。

## N002 奖励池调整

| 节点 | 候选池 | 默认展示 | 设计意图 |
| --- | --- | --- | --- |
| `N002 周会压力` | `C024`, `C025`, `C027`, `C021`, `C039` | `C024`, `C025`, `C027` | 保留导师沟通、组会汇报、经费申请的原始入口；用 `C021` 补照护恢复，用 `C039` 补反馈沉淀 |

默认展示仍保持旧体验，避免没有构筑倾向时奖励突然变陌生。

当玩家已经拿过导师/合作牌，例如 `C024 导师沟通`，`C039 会后纪要` 会因为 `mentor/cooperation` 标签命中而更容易出现在奖励三选一里。

## 实现内容

新增：

- `data/cards/reward/c039_meeting_minutes.tres`

更新：

- `data/encounters/n002_weekly_meeting.tres`

未新增效果类型；`C039` 复用现有效果：

- `gain_resource`
- `gain_block`
- `draw`
- 条件 `has_1_reputation`

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

数据和奖励权重验证：

```text
card_count=38
c039_summary=C039:会后纪要:1:mentor,cooperation,methodology
n002_pool=C024,C025,C027,C021,C039
n002_default=C024,C025,C027
n002_default_scores=C024:10|C025:10|C027:10|C021:10|C039:10
n002_mentor=C024,C039,C025
n002_mentor_scores=C024:18|C025:12|C027:12|C021:10|C039:14
c039_mentor_tooltip=获得 1 方法论笔记和 4 防护；若有声望，抽 1 张牌。|流派：导师人脉|推荐：已有导师、合作相关牌|标签：导师、合作、方法论
```

效果验证：

```text
c039_effect_no_rep=played=true rep=0 methodology=1 block=4 hand= discard=C039
c039_effect_with_rep=played=true rep=1 methodology=1 block=4 hand=C001 discard=C039
```

结果说明：

- `C039` 能正常加载，并进入总卡牌计数。
- `N002` 候选池已扩展为 5 张。
- 默认无倾向时，奖励仍展示 `C024/C025/C027`。
- 已有导师/合作倾向时，`C039` 会被推入三选一。
- 有声望时，`C039` 能额外抽 1 张牌。

## 下一步

1. `N001 普通压力` 候选池扩展已完成，见 [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md)。
2. `N004 截稿临近` 候选池扩展已完成，见 [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md)。
3. 观察 `C039` 是否让方法论笔记过早膨胀；如果中期 Boss 材料门槛变得太容易，再调整为只给防护和抽牌。
