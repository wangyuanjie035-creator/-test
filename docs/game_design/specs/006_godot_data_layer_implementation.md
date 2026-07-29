# Godot 数据层实现记录 v0.1

状态：已完成首批数据层落地，并通过 Godot 编辑器加载验证

创建日期：2026-05-26

关联文档：

- [004_godot_data_model.md](004_godot_data_model.md)
- [001_mvp_card_set.md](001_mvp_card_set.md)

## 本次目标

把 MVP 数据模型从文档推进到 Godot 项目文件：

- 建立 Resource 定义脚本。
- 建立数据目录。
- 落地 5 张初始牌、5 张状态牌和 1 个初始牌组。
- 提供数据加载器和验证脚本，为下一步战斗原型做准备。

## 新增目录

```text
res://scripts/data/
res://scripts/tools/
res://data/cards/base/
res://data/cards/reward/
res://data/cards/status/
res://data/bosses/
res://data/events/
res://data/decks/
```

## 新增脚本

| 文件 | 用途 |
| --- | --- |
| `scripts/data/effect_definition.gd` | 通用效果数据 |
| `scripts/data/card_definition.gd` | 卡牌数据 |
| `scripts/data/status_definition.gd` | 状态数据，后续可用于非卡牌状态 |
| `scripts/data/boss_definition.gd` | Boss 数据 |
| `scripts/data/boss_intent_definition.gd` | Boss 意图数据 |
| `scripts/data/event_definition.gd` | 事件数据 |
| `scripts/data/event_choice_definition.gd` | 事件选项数据 |
| `scripts/data/deck_definition.gd` | 牌组数据 |
| `scripts/data/game_data_catalog.gd` | 数据目录扫描与按 ID 加载 |
| `scripts/tools/generate_mvp_data.gd` | 一次性 MVP 数据生成器 |
| `scripts/tools/validate_game_data.gd` | Godot 编辑器内数据验证脚本 |

## 新增数据资源

基础卡：

- `C001` 查文献
- `C006` 写草稿
- `C011` 做实验
- `C020` 自我调整
- `C023` 请教师兄

状态牌：

- `S001` 拖延
- `S002` 焦虑
- `S004` 信息过载
- `S005` 恍惚
- `S010` 自我怀疑

牌组：

- `D001` 研究生初始牌组，15 张卡

## 验证结果

已用 PowerShell 做文件和引用一致性校验：

| 检查项 | 结果 |
| --- | --- |
| 基础卡 `.tres` 数量 | 5 |
| 状态牌 `.tres` 数量 | 5 |
| 初始牌组数量 | 1 |
| 初始牌组卡牌数 | 15 |
| 初始牌组缺失引用 | 0 |

已通过 Hastur editor executor 在 Godot 4.5.1 中加载验证：

```text
card_count=10
deck_count=1
deck_D001_size=15
deck_D001_missing=
```

后续奖励系统加入后，当前卡牌总数已扩展到 16。见 [010_reward_selection.md](010_reward_selection.md)。

## 当前限制和注意事项

本机 `godot` 可执行文件未在 PATH 或常见安装目录中找到，因此命令行校验暂不可用。

编辑器当前会话曾在 Resource 脚本未标记 `@tool` 时加载过 `.tres`，因此 helper 方法如 `DeckDefinition.size()` 仍可能在本会话里提示 placeholder。已给数据 Resource 脚本补上 `@tool`，并把验证脚本改为读取导出字段 `deck.card_ids.size()`。重启编辑器或重新打开项目后，脚本类缓存应刷新。

Godot 编辑器内验证脚本：

- `res://scripts/tools/validate_game_data.gd`

期望输出：

```text
cards=16
decks=1
deck_ok=D001 size=15
```

## 下一步

1. 最小战斗状态已完成，见 [007_minimal_battle_state.md](007_minimal_battle_state.md)。
2. 下一步接入极简战斗测试界面。
3. 在战斗原型里继续只依赖数据字段，不依赖硬编码卡牌。
