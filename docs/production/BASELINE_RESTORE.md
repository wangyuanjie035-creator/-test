# 基线恢复说明

适用快照：`.snapshots/lab_engine_baseline_2026-07-16.zip`

## 校验

恢复前对 ZIP 运行：

```powershell
Get-FileHash .snapshots\lab_engine_baseline_2026-07-16.zip -Algorithm SHA256
```

结果必须与 `BASELINE_2026-07-16.md` 记录一致。

## 恢复

1. 关闭正在运行的 Godot 编辑器和游戏实例。
2. 将 ZIP 解压到新的空目录，不覆盖唯一工作副本。
3. 使用 Godot 4.5.1 stable mono 打开解压目录中的 `project.godot`。
4. 等待首次导入完成，运行主场景。
5. 运行 `scripts/tools/validate_lab_engine.gd`，确认输出 `LAB_ENGINE_VALIDATION: PASS`。

快照包含 `addons/hasturoperationgd` 和 `GameExecutor` Autoload 配置。远程代理未启动时不影响核心游戏，但远程执行功能不可用；开发机需另行启动 Hastur broker-server。

该快照用于回退当前项目源文件，不包含 `.godot` 导入缓存、`.temp` 临时文件、用户设置、导出产物或 broker-server 本体。
