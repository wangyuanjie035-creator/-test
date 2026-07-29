# 清空测试局外存档规格 v0.1

状态：已完成首版实现，并通过 Godot 编辑器验证

创建日期：2026-05-27

关联文档：

- [014_meta_progression_save.md](014_meta_progression_save.md)
- [016_meta_carryover_preview.md](016_meta_carryover_preview.md)

## 目标

提供一个安全的测试入口，方便反复验证局外成长、开局带入和解锁效果。清空功能只服务开发测试，默认保护正式局外存档。

## 安全规则

- 正式存档路径为 `user://meta_progression_v1.json`。
- 测试按钮默认不允许清空正式存档。
- 当 `meta_save_path == MetaProgressionState.SAVE_PATH` 时，清空请求会返回 `ERR_UNAUTHORIZED`。
- 当 `meta_save_path` 指向测试路径时，按钮可以删除对应 JSON 文件。
- 清空成功后，测试 UI 会重开一局并刷新局外预览。

## 实现内容

更新：

- `scripts/run/meta_progression_state.gd`
  - 新增 `clear_save(path, allow_default_path=false)`。
  - 若未显式允许，正式路径会被拒绝清空。
  - 清空成功后重置内存中的局外资源状态。
- `scripts/ui/battle_test_scene.gd`
  - 新增“清空测试存档”按钮。
  - 新增 `last_clear_save_result`。
  - 新增 `get_last_clear_save_error()`、`was_last_clear_save_successful()` 供验证使用。
  - 正式路径下按钮禁用；测试路径下可用。

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

测试路径清空验证：

```text
seed_err=0
before_preview=局外带入：自我照护 | 累计结算 3 次 | 经验教训 16 | 心理韧性 2
before_has_u001=true
clear_error=0
clear_success=true
after_preview=局外带入：暂无 | 累计结算 0 次 | 经验教训 0 | 心理韧性 0
after_has_u001=false
test_file_exists_after=false
```

正式路径保护验证：

```text
official_clear_error=4
official_clear_success=false
```

结果说明：

- 测试路径可以被清空，清空后不会再带入 `U001`。
- 清空后开局预览会回到无局外资源状态。
- 正式局外存档路径会被拒绝清空，避免误删真实进度。

## 下一步

1. 第二个局外解锁已完成，见 [018_second_meta_unlock_card.md](018_second_meta_unlock_card.md)。
2. 做一个独立结算界面，让局外资源、新解锁和下一局带入更清楚。
3. 把测试工具与正式 UI 分离，避免后续发布版本露出开发按钮。
