# 127 候选池点位布局权重

## 目标

承接 [126_campus_seed_reroll_debug.md](126_campus_seed_reroll_debug.md)，让 `候选池地图` 不只按标签选点，也开始照顾校园区域分布。

本步只影响候选池地图的实际刷点结果。默认固定地图不变，123/124 的候选选择器审查也不变；布局权重作为 125 的“实际刷图保护层”之后的一层再平衡。

## 布局规则

- 候选池地图仍先执行标签选择器。
- 之后继续执行 125 的剧情路线保护，保证主线入口不缺失。
- 再进入布局再平衡：
  - 每个区域采用软上限，当前 12 点目标下约为单区域最多 4 个。
  - 若区域覆盖不足，优先补入未覆盖区域。
  - 只替换非剧情保护点。
  - 替换后 required tags 和已有 focus tags 不能掉到 0。

首版区域来自现有 `_get_campus_area_hint()`：

```text
宿舍、图书馆、实验楼、校园中庭、食堂、导师办公室、会议室
```

## 审查接口

- `get_stage_spawn_layout_summary()`
  - 输出区域分布、区域数、最大区域、资源点数和平均主线距离。
- `候选池地图` 和 `重随 Seed` 的 tooltip 会显示：
  - 当前生成来源。
  - 当前布局摘要。

示例：

```text
areas=宿舍1、图书馆4、实验楼1、校园中庭1、食堂2、导师办公室2、会议室1,unique=7,max=图书馆4,resources=7,avg_route_dist=416
```

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `CAMPUS_LAYOUT_MIN_UNIQUE_AREAS`。
  - 新增 `CAMPUS_LAYOUT_REBALANCE_ATTEMPTS`。
  - `_get_stage_generation_spawn_definitions()` 在路线保护后调用 `_rebalance_generation_spawn_layout()`。
  - 新增区域计数、最大区域、资源点数、平均主线距离审查函数。
  - 新增替换保护：剧情点不移除，required/focus 标签覆盖不掉线。

## 验证记录

远程 Godot 执行器验证：

```text
scene_reload=0
master1 count=12 missing= max=图书馆4 target=B001
master2 count=12 missing= max=导师办公室4 target=B002
doctor1 count=12 missing= max=图书馆3 target=N005
doctor2 count=12 missing= max=图书馆3 target=N006
doctor3 count=12 missing= max=导师办公室4 target=N007
doctor4 count=12 missing= max=图书馆4 target=E007
```

标签覆盖验证：

```text
master1 missing=0 focus=7/7
master2 missing=0 focus=7/7
doctor1 missing=0 focus=7/7
doctor2 missing=0 focus=6/6
doctor3 missing=0 focus=6/6
doctor4 missing=0 focus=6/6
```

布局摘要样例：

```text
doctor3 areas=宿舍1、图书馆3、食堂1、导师办公室4、会议室3,unique=5,max=导师办公室4,resources=6,avg_route_dist=148
doctor4 areas=宿舍1、图书馆4、实验楼2、校园中庭1、食堂1、导师办公室2、会议室1,unique=7,max=图书馆4,resources=5,avg_route_dist=174
```

## 手测重点

1. 默认不打开 `候选池地图` 时，固定地图不应改变。
2. 打开 `候选池地图` 后，实际可互动点仍应是 12 个。
3. `候选池地图` tooltip 应显示布局摘要。
4. 点击 `重随 Seed` 后，布局摘要可以变化，但主线目标仍应存在。
5. 六个阶段最大区域数应大致控制在 4 以内，避免点位全部堆在同一片建筑。
6. 若后续候选池扩到 20 个以上，应继续检查 required/focus 标签覆盖是否保持。

## 下一步

1. 已完成“候选地图审查面板”，见 [128_campus_candidate_audit_panel.md](128_campus_candidate_audit_panel.md)。
2. 也可以继续扩展每阶段候选池到 20 个以上，让布局权重有更大的选择空间。
