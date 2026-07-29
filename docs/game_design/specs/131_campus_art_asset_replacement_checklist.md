# 131 校园点位正式美术素材替换清单

## 目标

承接 [129_campus_marker_visual_variety_placeholders.md](129_campus_marker_visual_variety_placeholders.md) 和 [130_campus_marker_profile_legend.md](130_campus_marker_profile_legend.md)，把当前 `CampusMapMarker` 的 `_draw()` 像素占位 profile 整理成正式美术素材需求表。

本步只做素材规划和验收标准，不改渲染逻辑。后续拿到 PNG 后，再做“贴图优先、代码占位兜底”的接入。

## 统一规格

- 格式：透明背景 PNG。
- 风格：2D 像素风，校园俯视/轻斜视角，轮廓清晰。
- 建议画布：`64x64`。小物件也放在同一画布里，方便统一锚点。
- 建议锚点：底部中心，约等于画布坐标 `(32, 52)`。
- 可视主体：尽量落在 `x=8..56`、`y=6..56` 内。
- 阴影：素材内可以自带 1 个软像素阴影；若后续统一由代码绘制阴影，素材阴影应可移除。
- 帧数：首版静态 1 帧即可；可选 2-3 帧 idle 抖动、灯光闪烁或纸张轻摆。
- 导入：Godot Import 使用 Lossless，Filter 设为 Nearest，Mipmaps 关闭。
- 命名：建议放入 `assets/campus/markers/`，文件名使用 profile id，例如 `advisor_npc.png`。

## Profile 清单

| profile id | 图例语义 | 当前占位形状 | 素材内容 | 优先级 | 备注 |
| --- | --- | --- | --- | --- | --- |
| `npc_scholar` | 交流 | NPC | 普通研究生或校园学术 NPC | P0 | 默认 fallback，任何未识别交流点都会用它 |
| `advisor_npc` | 导师 | 讲义 | 导师角色，手持讲义或批注纸 | P0 | 需要比普通 NPC 更有权威感，但不要做成 Boss |
| `advisor_notice` | 导师 | 便签 | 带导师批注/红笔的小公告 | P1 | 事件点，和导师 NPC 区分开 |
| `peer_npc` | 同门 | 双人 | 两个同门讨论或协作的剪影 | P0 | 用于合作、同门、人脉类学术交流 |
| `lab_equipment` | 设备 | 仪器 | 实验台、电脑、显微镜或设备面板 | P0 | 设备/实验/数据类点位的核心识别物 |
| `library_stack` | 资料 | 书堆 | 书堆、文献夹、资料柜 | P1 | 图书馆、文献、论文碎片相关交流 |
| `committee_panel` | 委员会 | 评审席 | 三人评审席、会议桌或投影审阅 | P0 | 博士阶段高频，需要清楚区别于普通 NPC |
| `rest_corner` | 休息 | 长椅 | 长椅、饮料、台灯或食堂角落 | P2 | 自我调整、食堂、休息事件 |
| `challenge_gate` | Boss | 门 | 通用挑战门或会议室入口 | P0 | 开题、中期、盲审等通用 Boss 可先复用 |
| `committee_gate` | 委员会 | 门 | 带评审席/三人标识的门 | P1 | 委员会考试、资格考核类 Boss |
| `defense_gate` | 答辩 | 门 | 答辩会场门、讲台、屏幕或答辩牌 | P0 | 博三/博四关键 Boss，建议更醒目 |
| `notice_board` | 事件 | 公告 | 通用校园公告栏 | P0 | 普通事件默认图标 |
| `admin_notice` | 行政 | 公告 | 蓝色/盖章/表格感行政通知 | P1 | 基金、申请、行政窗口 |
| `revision_notice` | 返修 | 公告 | 红色返修单、批注、重投标记 | P1 | 博四返修线需要强识别 |
| `resource_cache` | 补给 | 箱 | 通用补给箱或文件袋 | P0 | 未识别资源的 fallback |
| `data_cache` | 数据 | 样本 | 试管、硬盘、数据样本盒 | P0 | 数据补给高频 |
| `draft_cache` | 草稿 | 纸页 | 草稿纸、文档页、订书钉 | P0 | 草稿补给高频 |
| `funds_cache` | 经费 | 票据 | 经费单、报销票据、金币标记 | P1 | 项目线、基金窗口 |
| `inspiration_cache` | 灵感 | 灯泡 | 灯泡、便签火花、想法气泡 | P1 | 灵感补给 |
| `notes_cache` | 笔记 | 本子 | 方法论笔记或经验教训本 | P1 | `methodology_notes` 和 `experience_lessons` 共用 |
| `paper_cache` | 论文 | 碎片 | 论文碎片、引用页、审稿意见页 | P0 | 博士线和答辩线高频 |
| `safehouse_gate` | 住屋 | 门 | 宿舍门、出租屋门或安全屋入口 | P0 | 安全返回住屋入口，搜打撤循环的关键识别点 |

## 推荐素材包结构

```text
assets/
  campus/
    markers/
      advisor_npc.png
      advisor_notice.png
      peer_npc.png
      lab_equipment.png
      library_stack.png
      committee_panel.png
      rest_corner.png
      challenge_gate.png
      committee_gate.png
      defense_gate.png
      notice_board.png
      admin_notice.png
      revision_notice.png
      resource_cache.png
      data_cache.png
      draft_cache.png
      funds_cache.png
      inspiration_cache.png
      notes_cache.png
      paper_cache.png
      safehouse_gate.png
      npc_scholar.png
```

如果做动画，建议首版仍保持单文件命名，横向 spritesheet：

```text
advisor_npc.png  # 64x64 静态
advisor_npc_idle.png  # 192x64，3 帧 idle
```

## 替换接入建议

1. 保留当前 `CampusMapMarker._draw()` 占位逻辑作为 fallback。
2. 新增 profile 到 `Texture2D` 的映射，优先加载 `assets/campus/markers/{profile}.png`。
3. 如果贴图不存在，继续走当前 `_draw()`，保证开发期不会因为缺素材中断。
4. 贴图接入后，`get_marker_visual_profile_legend_text()` 不需要改动，因为它依赖 profile，而不是具体绘制方式。
5. 贴图接入后，小地图仍可先使用当前点色逻辑，不急着同步缩略图素材。

## 验收标准

- 正式素材替换后，固定地图与候选池地图仍能正常生成 12 个点位。
- 图例中的每个 profile 都能在 `assets/campus/markers/` 找到对应 PNG，或明确标记为 fallback。
- `advisor_npc`、`peer_npc`、`lab_equipment`、`committee_panel`、`defense_gate`、`paper_cache` 在 100% 缩放下应能一眼区分。
- 所有素材在 Godot 中应保持像素锐利，不应出现模糊边缘。
- 素材不应遮挡靠近信息卡、底部交互提示、右上任务视图或战斗入口。
- 资源点的脉冲、剧情目标高亮、条件不足标记和聚焦框仍应覆盖在素材之上。

## 手测重点

1. 打开 `候选池地图`，检查图例列出的 profile 是否都能在地图上找到对应视觉对象。
2. 切换到博三，检查 `committee_panel` 和 `defense_gate` 的正式素材是否明显区别于普通 Boss 门。
3. 点击 `重随 Seed`，检查新出现的 profile 是否仍能加载对应素材或 fallback。
4. 拾取 `data_cache`、`draft_cache`、`paper_cache` 等资源后，素材消失、资源回写和浮字反馈应保持正常。
5. 靠近任意替换后的点位，底部提示和信息卡不应被素材遮挡。

## 下一步

1. `132_campus_marker_texture_fallback.md` 已接入 profile 贴图加载、缺图 fallback 和 Godot 验证。
2. 也可以继续扩展每阶段候选池到 20 个以上，让这些正式素材有更多出现机会。
