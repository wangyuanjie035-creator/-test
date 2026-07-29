# 134 校园生成阶段主题权重

## 目标

承接 [133_campus_candidate_pool_20_expansion.md](133_campus_candidate_pool_20_expansion.md)，在候选池地图中加入“阶段主题权重”。

每次校园生成会根据当前阶段和 Seed 选择一个主题，例如实验日、写作日、委员会日、答辩日、返修日。候选点如果带有该主题标签，会在候选评分中获得加分。

本步只影响候选池地图的选择倾向，不改变：

- 固定地图 `interactions`。
- 每次实际刷出的点位数量，仍为 12。
- 主线必经路线保护。
- 必需标签和 focus 标签覆盖。
- 点位布局再平衡。

## 主题池

主题由阶段资源的 `generation_theme_ids` 声明，实际主题由 Seed 可复现地选出。

| theme id | 中文名 | 主题标签 |
| --- | --- | --- |
| `experiment_day` | 实验日 | 实验室、设备、数据 |
| `writing_day` | 写作日 | 写作、草稿、论文碎片、图书馆 |
| `social_day` | 同门日 | 同门、合作、社交、会议 |
| `advisor_day` | 导师日 | 导师、方向、会议、方法 |
| `recovery_day` | 缓冲日 | 照护、食堂、灵感、同门 |
| `committee_day` | 委员会日 | 委员会、考核、方法、声望 |
| `transfer_day` | 转博日 | 导师、委员会、声望、写作 |
| `project_day` | 项目日 | 项目、会议、数据、方法 |
| `funds_day` | 经费日 | 经费、行政、项目 |
| `seminar_day` | 沙龙日 | 沙龙、同门、方法、声望 |
| `defense_day` | 答辩日 | 答辩、委员会、草稿、方法 |
| `revision_day` | 返修日 | 返修、写作、委员会、草稿 |
| `data_repair_day` | 数据修补日 | 返修、数据、实验室、方法 |

## 阶段配置

| 阶段 | 可选主题 |
| --- | --- |
| 研一 | 实验日、写作日、导师日、同门日、缓冲日 |
| 研二 | 写作日、实验日、委员会日、转博日、导师日 |
| 博一 | 项目日、委员会日、经费日、沙龙日、导师日 |
| 博二 | 项目日、同门日、实验日、经费日、数据修补日 |
| 博三 | 答辩日、委员会日、写作日、同门日、缓冲日 |
| 博四 | 返修日、答辩日、数据修补日、同门日、缓冲日 |

## 实现记录

- [campus_stage_definition.gd](../../../scripts/data/campus_stage_definition.gd)
  - 新增 `generation_theme_ids: Array[StringName]`。
- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增主题 ID 常量、主题标签映射和中文名映射。
  - 新增 `get_stage_generation_theme_summary()`。
  - 候选评分 `_score_generation_candidate()` 加入主题标签加分。
  - `get_stage_generation_selection_audit_summary()` 增加 `theme` 和 `theme_hits`。
  - 测试区审查面板与 Seed 按钮 tooltip 显示当前主题。
- `data/campus/stages/*.tres`
  - 每个阶段补充 `generation_theme_ids`。

## 验证记录

远程 Godot 执行器验证：

```text
scene_reload=0
master1 导师日｜导师 / 方向 / 会议 / 方法 | pool=20,target=12,selected=12,missing=0,focus_hits=7/7,theme=advisor_day,theme_hits=5/12
master2 委员会日｜委员会 / 考核 / 方法 / 声望 | pool=20,target=12,selected=12,missing=0,focus_hits=7/7,theme=committee_day,theme_hits=8/12
doctor1 沙龙日｜沙龙 / 同门 / 方法 / 声望 | pool=20,target=12,selected=12,missing=0,focus_hits=7/7,theme=seminar_day,theme_hits=5/12
doctor2 实验日｜实验室 / 设备 / 数据 | pool=20,target=12,selected=12,missing=0,focus_hits=6/6,theme=experiment_day,theme_hits=5/12
doctor3 委员会日｜委员会 / 考核 / 方法 / 声望 | pool=20,target=12,selected=12,missing=0,focus_hits=6/6,theme=committee_day,theme_hits=9/12
doctor4 返修日｜返修 / 写作 / 委员会 / 草稿 | pool=20,target=12,selected=12,missing=0,focus_hits=6/6,theme=revision_day,theme_hits=12/12
seed_diff=theme_a=导师日｜导师 / 方向 / 会议 / 方法,theme_b=写作日｜写作 / 草稿 / 论文碎片 / 图书馆,ids_changed=true
```

验证重点：

- 6 个阶段仍然保持 `pool=20,target=12,selected=12`。
- 必需标签缺失为 0。
- focus 标签覆盖保持满覆盖。
- Seed 改变后，主题和候选组合可以变化。
- 主题命中数可审查。

## 手测重点

1. 打开 `候选池地图`，左上测试区应出现 `主题：...`。
2. 点击 `重随 Seed`，主题可能变化，候选点组合和图例也应同步变化。
3. 每次生成仍应显示 `pool=20,target=12,selected=12`。
4. `路线` 行仍应显示 `缺失无`。
5. 研二如果抽到委员会日，应更容易看到盲审/委员会/考核相关点。
6. 博三如果抽到答辩日或委员会日，应更容易看到答辩、委员会、方法类点。
7. 博四如果抽到返修日，应更容易看到返修、写作、委员会和草稿类点。

## 下一步

1. 自动主题方案已在 [135_campus_generation_theme_choices.md](135_campus_generation_theme_choices.md) 修正为肉鸽式三选一。
2. 后续可以做“主题选择与奖励池联动”：让写作主题、实验主题、答辩主题影响战斗后的奖励推荐。
