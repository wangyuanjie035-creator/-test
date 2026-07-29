# 局外资源存档规格 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [03_meta_progression_and_legacy.md](../03_meta_progression_and_legacy.md)
- [013_run_settlement.md](013_run_settlement.md)
- [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md)

## 目标

把阶段结算产生的局外资源真正累计到本地存档。玩家完成路线或进入坏结局后，不只看到本局奖励，还能看到累计资源和解锁结果。

## 存档路径

正式路径：

```text
user://meta_progression_v1.json
```

验证路径：

```text
user://meta_progression_test_codex.json
```

测试 UI 默认使用正式路径，但暴露 `meta_save_path` 变量，自动验证时可切到测试路径，避免污染真实进度。

## 存档结构

```json
{
  "version": 1,
  "runs_completed": 2,
  "resources": {
    "experience_lessons": 16,
    "methodology_notes": 8,
    "psychological_resilience": 2,
    "paper_fragments": 1,
    "black_history_archive": 1
  },
  "unlocks": ["self_care_seed", "revision_strategy_seed", "revision_matrix_seed"],
  "last_outcome_id": "supplementary_defense_failed"
}
```

## 资源累计规则

- 每次进入阶段结算后，读取已有局外存档。
- 将本次 `settlement.resources` 加到累计资源。
- `runs_completed` 增加 1。
- `last_outcome_id` 记录最近一次结算类型。
- 写回 JSON 存档。
- 若没有旧存档，则创建新存档。
- 若旧存档缺少某个资源字段，则按 0 处理。

## 当前解锁

| 解锁 ID | 条件 | 定位 |
| --- | --- | --- |
| `self_care_seed` | 累计经验教训达到 10 | 解锁 `U001 自我照护`，新局加入初始牌组 |
| `revision_strategy_seed` | 累计论文碎片达到 1 | 解锁 `U002 返修策略`，新局加入初始牌组 |
| `revision_matrix_seed` | 最近一次结算为 `supplementary_defense_failed` | 解锁 `U003 返修矩阵`，新局加入初始牌组 |

首个真实解锁卡见 [015_first_meta_unlock_card.md](015_first_meta_unlock_card.md)。第二个局外解锁见 [018_second_meta_unlock_card.md](018_second_meta_unlock_card.md)。补答辩失败专属解锁见 [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md)。

## 实现内容

新增脚本：

- `scripts/run/meta_progression_state.gd`
  - `load_from_disk(path)`：读取 JSON 存档。
  - `save_to_disk(path)`：写入 JSON 存档。
  - `apply_settlement(settlement, path)`：累计结算资源、刷新解锁并保存。
  - `get_resource(resource_id)`：读取累计资源。
  - `to_debug_dict()`：输出验证状态。

更新：

- `scripts/ui/battle_test_scene.gd`
  - 新增 `META_PROGRESSION` 预加载。
  - 新增 `meta_progression`、`settlement_save`、`meta_save_path`。
  - 进入结算时自动调用 `MetaProgressionState.apply_settlement()`。
  - 结算文本追加累计局外资源和新解锁信息。
  - 新增 `get_settlement_save_error()`、`get_meta_runs_completed()`、`get_meta_resource()`、`get_meta_unlocks()` 供验证使用。

## 验证记录

验证环境：

- Godot editor executor
- Godot 4.5.1
- 项目路径：`D:/1/+test/`

编译验证：

```text
reload_route_state.gd=0
reload_run_settlement.gd=0
reload_meta_progression_state.gd=0
reload_battle_state.gd=0
reload_battle_test_scene.gd=0
```

累计验证：

```text
success_save_error=0
success_runs=1
success_lessons_total=14
success_methodology_total=8
success_paper_total=1
success_unlocks=self_care_seed,revision_strategy_seed
burnout_save_error=0
burnout_runs=2
burnout_lessons_total=16
burnout_methodology_total=8
burnout_resilience_total=2
burnout_paper_total=1
burnout_black_history_total=1
burnout_unlocks=self_care_seed,revision_strategy_seed
disk_loaded=true
disk_runs=2
disk_lessons=16
disk_resilience=2
disk_unlocks=self_care_seed,revision_strategy_seed
```

结果说明：

- 成功结算能创建存档并累计资源。
- 坏结局结算能读取同一存档并继续累计资源。
- 经验教训达到 10 后会记录 `self_care_seed` 解锁。
- 论文碎片达到 1 后会记录 `revision_strategy_seed` 解锁。
- 重新从磁盘读取测试存档后，资源总量和解锁仍然存在。

## 下一步

1. `self_care_seed` 已接入初始牌组，见 [015_first_meta_unlock_card.md](015_first_meta_unlock_card.md)。
2. `revision_strategy_seed` 已接入初始牌组，见 [018_second_meta_unlock_card.md](018_second_meta_unlock_card.md)。
3. `revision_matrix_seed` 已接入初始牌组，见 [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md)。
4. 做一个独立结算界面，让局外资源和解锁更清楚。
