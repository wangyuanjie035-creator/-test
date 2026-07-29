# 开局局外成长预览规格 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [014_meta_progression_save.md](014_meta_progression_save.md)
- [015_first_meta_unlock_card.md](015_first_meta_unlock_card.md)
- [018_second_meta_unlock_card.md](018_second_meta_unlock_card.md)
- [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md)

## 目标

让局外成长从“幕后生效”变成“开局可见”。玩家开始新旅程时，应能立刻看到本局带入了哪些解锁，以及当前累计局外资源的大致状态。

## 显示内容

测试 UI 在标题下方显示一行局外成长预览：

```text
局外带入：自我照护 | 累计结算 2 次 | 经验教训 16 | 心理韧性 2
```

没有局外解锁时：

```text
局外带入：暂无 | 累计结算 0 次 | 经验教训 0 | 心理韧性 0
```

首版只显示最关键的两个资源：

- 经验教训：对应第一个解锁条件。
- 心理韧性：对应自我照护和坏结局正反馈方向。

## 名称映射

内部解锁 ID 不直接展示给玩家：

| unlock_id | 显示名称 |
| --- | --- |
| `self_care_seed` | 自我照护种子 |
| `revision_strategy_seed` | 返修策略种子 |
| `revision_matrix_seed` | 返修矩阵种子 |

如果该解锁已经转化成本局带入卡，则预览优先显示卡牌名，例如 `自我照护`、`返修策略` 或 `返修矩阵`，而不是显示内部种子名称。

## 实现内容

更新：

- `scripts/run/meta_progression_state.gd`
  - 新增 `get_unlock_display_name(unlock_id)`。
  - 新增 `get_unlock_display_names()`。
- `scripts/ui/battle_test_scene.gd`
  - 新增 `meta_preview_label`。
  - 新增 `carried_unlock_cards`，记录本局实际带入的局外卡。
  - 新增 `get_meta_preview_text()`、`get_carried_unlock_card_ids()` 供验证使用。
  - `_refresh_meta_preview()` 根据存档和带入卡生成预览文本。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
reload_meta_progression_state.gd=0
reload_battle_test_scene.gd=0
```

无解锁预览验证：

```text
locked_preview=局外带入：暂无 | 累计结算 0 次 | 经验教训 0 | 心理韧性 0
locked_carried=
locked_has_u001=false
```

有解锁预览验证：

```text
seed_save_err=0
unlock_display=自我照护种子
unlocked_preview=局外带入：自我照护 | 累计结算 2 次 | 经验教训 16 | 心理韧性 2
unlocked_carried=U001
unlocked_has_u001=true
unlocked_deck_size=16
```

结果说明：

- 无存档或无解锁时，开局预览显示暂无带入。
- `self_care_seed` 的内部 ID 会映射为“自我照护种子”。
- 当 `self_care_seed` 转化为实际带入卡时，开局预览显示“自我照护”。
- 预览文本与实际牌组一致：显示带入时，初始牌组确实包含 `U001`。

## 下一步

1. 清空测试存档按钮已完成，见 [017_clear_test_meta_save.md](017_clear_test_meta_save.md)。
2. 第二个局外解锁已完成，见 [018_second_meta_unlock_card.md](018_second_meta_unlock_card.md)。
3. 补答辩失败专属解锁已完成，见 [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md)。
4. 做一个独立结算界面，让局外资源、新解锁和下一局带入更清楚。
