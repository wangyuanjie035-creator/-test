# 阶段 5：累计课题 UI 设计草案

状态：待 UI 审查与用户确认，不得据此实现正式规则。

## 1. 设计目标

- 玩家在第 1 天就能看到前三日课题、当前累计值、目标值和奖励。
- 信息提示不打断候选、超频与连锁预测；第 4 天不使用模态弹窗。
- 达成时提供一次清晰但短促的正反馈；未达成明确说明“无惩罚”。
- UI 只消费控制器提供的快照 DTO，不读取事件日志或模拟器内部字段。

## 2. 放置位置

放在现有右侧 `LabSidebarView` 内，顺序为“今日状态 → 累计课题 → 日志 → 操作按钮”。课题是跨日状态与结算信息，不挤占左侧生产线、连锁预测、工位和候选区。

```text
LabWorkbench (Control, Full Rect)
└─ MarginContainer
   └─ RootVBox
      ├─ LabHudView
      └─ BodyHBox
         ├─ WorkspaceVBox
         │  ├─ ProductionTitle
         │  ├─ LabChainForecastView
         │  ├─ SlotGrid
         │  ├─ CandidateTitle
         │  └─ LabCandidatePanel
         └─ LabSidebarView
            └─ SidebarVBox
               ├─ StatusLabel
               ├─ LabTopicPanel     ← 新增，可折叠、非模态
               ├─ LogLabel          ← EXPAND_FILL，承担高度收缩
               ├─ RunButton
               └─ SkipButton
```

不得把课题文本拼进 HUD 资源行、侧边栏状态文本或候选描述；课题使用侧边栏内独立组件。

## 3. `LabTopicPanel` 节点结构

`LabTopicPanel` 使用独立脚本和容器布局，不由 `LabWorkbench` 或 `LabSidebarView` 动态拼接内部控件。Godot 4.5 使用 `FoldableContainer`，第 5 天后自动折叠但仍可复查。

```text
LabTopicPanel (FoldableContainer, title="累计课题")
└─ ContentMargin (MarginContainer)
   └─ TopicVBox (VBoxContainer)
      ├─ HeaderRow (HBoxContainer)
      │  ├─ TopicNameLabel     “图表预演”
      │  └─ DayBadgeLabel      “第 4 天结算”
      ├─ GoalLabel             “目标：前三日累计产出 3 图表”
      ├─ ProgressRow (HBoxContainer)
      │  ├─ TopicProgressBar
      │  └─ ProgressTextLabel  “2 / 3”
      ├─ StatusLabel           “今日 +1 · 未达成无惩罚”
      └─ RewardLabel           “达成奖励：论文 +5”
```

- `PanelContainer` 使用主题继承的 `StyleBoxFlat`，不新增图片资产。
- 内边距 10–12 px；行间距 6–8 px；1280×720 展开态高度预算 118–150 px。
- `TopicProgressBar` 不显示百分比，只用文本给出精确值。
- 所有标签 `mouse_filter = MOUSE_FILTER_IGNORE`、`focus_mode = FOCUS_NONE`；`FoldableContainer` 标题可聚焦并进入键盘/手柄焦点链。

## 4. 状态与文案

### 第 1–3 天：进行中

- 标题：`累计课题 · {课题名}`
- 进度：`累计正产出{资源名} {current}/{target}`，常驻补充“后续消费不扣减累计值”，不得让玩家误认为当前库存。
- 时机：`第 4 天停机判定后结算`
- 奖励：`达成奖励：{奖励资源} +{requested}`
- 辅助说明：`今日 +{delta}` 或 `今日无新增`；`可追逐，也可放弃；未达成无惩罚。`

接近达成时仅改变进度条颜色，不使用闪烁：

- 0%–66%：中性蓝灰。
- 67%–99%：青色。
- 100%：薄荷绿，并显示 `已达成，等待第 4 天结算`。

### 第 4 天：已达成

- 标题：`课题达成！{课题名}`
- 结果：`{current}/{target}`
- 奖励：`奖励已入库：{奖励资源} +{actual}`
- 若出现钳制：追加 `（库存已满，{overflow} 未加入）`，不得显示请求值冒充实际值。
- 辅助说明：`奖励只入库，不主动触发连锁。`

### 第 4 天：未达成

- 标题：`课题未达成 · {课题名}`
- 结果：`{current}/{target}`
- 说明：`本局无奖励，也无惩罚。生产线照常运行。`
- 不使用红色、失败音效或屏幕震动；这是主动放弃也可能合理的支线目标。

### 第 5–8 天

- `LabTopicPanel` 自动折叠为一行摘要，但玩家可手动展开复查。
- 达成折叠标题：`累计课题 ✓ 已结算：{reward_short}`。
- 未达成折叠标题：`累计课题 — 未完成`。
- 第 4 天结果写入侧边栏日志一次，不每天重复。
- 帮助页保留课题规则说明。

### 结局摘要

结局面板统计行下新增一行：

- 达成：`课题：图表预演 · 达成 · 论文 +5`
- 未达成：`课题：图表预演 · 2/3 · 无奖励/无惩罚`

课题摘要不得挤占既有胜负断点与建议文本；空间不足时放在统计行之后、断点之前。

## 5. 动效与声音

- 第 1 天首次出现：150 ms 卡内淡入，不移动或推挤 Body。
- 进度增长：进度条 180–220 ms 平滑补间；同时只播放一次轻量 Token/数字跳变，不逐事件闪烁课题条。
- 第 4 天达成：边框和标题在 240 ms 内由青色过渡到薄荷绿；奖励文本轻微放大至 1.04 后回到 1.0，总时长不超过 320 ms。
- 第 4 天未达成：120 ms 降低饱和度，不震动、不播放失败音。
- 若现有“低动效”设置启用，所有 Tween 立即完成，仅保留颜色和文案变化。
- 奖励使用独立轻量成功 Cue，不复用论文完成或关键突破的强反馈。

所有 Tween 由 `LabTopicPanel` 自己持有；重开、结局或节点退出时统一 `kill()`。同一 `settled` 快照重复渲染不得重播动画。

## 6. 响应式规则

- 侧边栏逻辑宽度保持最小 300 px，不因 1080p 按比例扩大为 450 逻辑像素。
- 1280×720 下展开态控制在 118–150 px；目标、状态和奖励各最多两行，日志使用 `EXPAND_FILL` 承担高度收缩。
- 16:10 下利用增加的垂直空间，不放大课题条。
- 最小正文字号 15 px，课题名 17–18 px；颜色对比不足时必须同时依赖状态文字，不只依赖颜色。
- 项目保持 `canvas_items` 缩放；测试 1280×720、1920×1080、1920×1200，不在 `_process()` 中轮询布局。
- 进度条可以 clamp 到目标值，但文本必须显示真实超额值，例如 `5/3`。
- 新模块使用 `tr()` 语义 key；不得把格式化后的中文句子作为翻译 key。

## 7. 控制器—视图契约

正式实现时，控制器只暴露可序列化快照：

```gdscript
{
    "topic_id": StringName,
    "display_name": String,
    "resource_name": String,
    "current": int,
    "target": int,
    "status": StringName, # active / achieved_waiting / rewarded / missed
	"settled": bool,
	"today_delta": int,
    "review_day": int,
    "reward_resource_name": String,
    "reward_requested": int,
    "reward_actual": int,
    "reward_overflow": int,
}
```

- `LabTopicPanel.render(snapshot)` 只负责渲染，不计算是否达成或奖励。
- 累计账本由控制器读取第 1–3 天已结算事件的正向 delta 更新；UI 不解析 RichText 日志。
- 第 4 天奖励在控制器完成停机判定后原子结算，写入不可重复的 `settled` 快照，并通过 `begin_day()` 预览一起返回，确保同 Seed 确定性。
- 课题结果必须进入运行历史和结局分析，重复刷新 UI 不得重复发奖。
- 结局摘要复用第 4 天冻结快照，不按结局资源重新计算。

## 8. UI 验收门槛

- 第一次看到课题条的玩家能在 10 秒内回答目标、截止日、奖励和失败是否有惩罚。
- 第 3 天能准确说出当前累计值；不得把库存值误认为累计值。
- 第 4 天能分辨奖励“已入库”与“已触发连锁”。
- 1280×720、1920×1080、1280×800 无遮挡、无候选区压缩、无侧边栏按钮下沉出屏。
- 重开十次无残留课题状态、Tween、重复奖励或重复日志。
- Foldable 标题可通过键盘/手柄聚焦和展开；成败同时使用文字与符号，不只依赖颜色。
- 结局面板继续优先显示胜负断点，课题摘要不造成文本裁切。
