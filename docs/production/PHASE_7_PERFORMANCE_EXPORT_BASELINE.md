# 阶段 7：性能与 Windows 导出基线

记录日期：2026-07-19  
状态：发布隔离返工后通过自动门禁，继续补充帧时间与完整发布回归。

## 已完成

- 将远程执行器自动加载改为 `scripts/dev/dev_game_executor_bridge.gd`；仅编辑器运行时动态加载插件，发布包不再依赖 `addons/hasturoperationgd`。
- 新增 Windows Desktop x86_64 Release 导出预设，隔离插件、测试、文档、内部工具、临时文件与构建产物。
- 新增稳定性冒烟：同场景重开 40 次、完整销毁重建 8 次，检查节点、Tween 与 Audio Bus 不持续增长。
- 统一门禁扩展为 compile、unit、golden、scene-smoke、layout-smoke、stability-smoke 六道检查，当前全部通过。
- 安装 Godot 4.5.1 Mono 的 Windows x86_64 Debug/Release 模板；仅远程抽取所需条目，未下载或写入完整 1.19 GB 模板包。
- 成功生成独立 Windows 发布包，并在脱离编辑器的进程中完成无窗口启动/退出冒烟。

## 当前测量

| 项目 | 结果 |
|---|---:|
| 同场景重开 | 40 次通过 |
| 完整 8 天模拟与结算 | 4 次预热 + 12 次测量通过 |
| 真实逐日 UI 播放 | 1 次预热 + 4 次 `_run_day()` 测量通过 |
| 帮助/设置模态开关 | 24 轮通过 |
| 完整场景重建 | 8 次通过 |
| 对象增量容差 | 预热后不超过 32 个 |
| 静态内存增量容差 | 预热后不超过 512 KiB |
| 慢泄漏趋势 | 完整局与 UI 播放分别分段取中点；各后半段对象增量不超过 4、静态内存不超过 256 KiB |
| 发布 EXE | 96,864,768 bytes |
| 发布 PCK | 211,764 bytes |
| 发布包可枚举条目 | 116 |
| 发布包启动错误 | 0 |
| 开发插件/测试/文档/工具及旧原型泄漏 | 0（直接枚举审计 ZIP） |
| 编辑器内游戏空闲 FPS | 144（连续 12 次采样，目标 60） |
| 编辑器游戏工作集 | 152.95 MiB（5 次稳定样本） |
| 编辑器游戏专用 GPU 内存 | 153.57 MiB（Windows GPU Process Memory） |
| Windows Release 工作集 | 441.79–442.37 MiB（5 次样本） |
| Windows Release 私有内存 | 599.73–600.50 MiB（5 次样本） |
| Windows Release 专用 GPU 内存 | 170.01 MiB |
| Windows Release GPU 本地占用 | 182.02 MiB |
| Windows Release 句柄 / 线程 | 769–773 / 48–49，采样末段稳定 |
| 结算播放帧时间 | 4 次、1253 帧：平均 6.938 ms，P95 6.944 ms，最差 7.575 ms |
| 结算播放慢帧 | 超过 16.67 ms：0 帧 |
| 结算渲染进程工作集峰值 | 449.04 MiB |
| 结算渲染进程私有内存峰值 | 530.35 MiB |
| 结算渲染进程专用 GPU 峰值 | 173.75 MiB |

结算渲染基准使用一次预热和 4 次真实 `_run_day()`，逐帧采样并由 Windows 同步采集进程/GPU 数据。自动门槛为 P95 不超过 16.67 ms、最差帧不超过 50 ms、慢帧比例不超过 1%。

进程数据由 `capture_windows_process_metrics.ps1` 采集。发布包当前使用 Mono 模板，因此即使项目为纯 GDScript，进程基线也明显高于编辑器内游戏实例。当前仅建立基线，不在缺少峰值证据时贸然更换发布模板；峰值若逼近首发预算，再评估独立 Standard 导出链路。

## 独立审查

非实现技术监察 Agent 首轮判定“返工”，发现旧发布脚本只扫描导出日志而没有检查 PCK 本体。完成白名单入口、递归排除、真实 ZIP 条目枚举和 Godot 日志阻断后复审为“有条件通过”：严重/高问题全部关闭。稳定性 smoke 随后扩展到完整运行、结算与模态循环；剩余外部条件是后续干净 Windows 环境/签名验证。

## 一键发布

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/tools/export_lab_windows.ps1 -GodotPath "G:\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64_console.exe"
```

默认先运行六道门禁，再清理旧产物、发布、扫描开发内容泄漏，最后启动导出包做冒烟。只有在门禁刚刚独立通过时，才可使用 `-SkipGate`。

## 已知环境提示

当前编辑器为 Mono 版，但项目没有 C# 源码。命令行导出会提示本机缺少 .NET SDK 10.0.1；该提示来自 Mono 编辑器插件，导出退出码、发布产物和独立启动均正常，不属于本项目运行错误。若未来加入 C#，必须先安装匹配 SDK 并把该提示提升为发布阻断。

## 下一轮门槛

- 暂定首发发布预算：工作集峰值低于 768 MiB、专用 GPU 内存低于 256 MiB；当前结算峰值通过。
- 对导出包验证设置保存、同 Seed 重开、换 Seed 重开和正常退出。
- 阶段结束前由非实现 Agent 独立审查性能、导出隔离与发布可重复性。
