# 133 校园候选池扩展到 20

## 目标

承接 [124_campus_candidate_pool_expansion.md](124_campus_candidate_pool_expansion.md)、[127_campus_candidate_layout_weighting.md](127_campus_candidate_layout_weighting.md) 和 [132_campus_marker_texture_fallback.md](132_campus_marker_texture_fallback.md)，把每个阶段的 `generation_candidate_interactions` 从 16 个扩展到 20 个。

本步只扩展候选池，不改变固定地图 `interactions`，也不改变每次实际刷出的目标数量。当前规则仍是：

- 固定地图：12 个点位。
- 候选池地图：从 20 个候选里按阶段标签和 Seed 选出 12 个。
- 主线必经路线仍由路线保护逻辑兜底。

## 新增候选点

### 研一

- `master1_literature_method_corner`：文献方法角，补充图书馆/方法/写作交流。
- `master1_lab_open_bench`：开放实验台，补充实验楼数据资源。
- `master1_advisor_direction_card`：导师方向卡，补充导师事件。
- `master1_canteen_breathing_note`：食堂喘息便签，补充自我照护与灵感资源。

### 研二

- `master2_review_storyboard_wall`：盲审叙事墙，补充写作/委员会压力。
- `master2_replication_lab_log`：复现实验日志，补充数据/设备资源。
- `master2_transfer_peer_roundtable`：转博同门圆桌，补充转博窗口相关事件。
- `master2_reviewer_response_draft`：审稿回复草稿，补充草稿/委员会资源。

### 博一

- `doctor1_committee_reading_room`：委员会阅读室，补充资格考和委员会交流。
- `doctor1_project_data_clean_room`：项目数据清理间，补充项目数据资源。
- `doctor1_advisor_grant_outline`：导师基金提纲，补充导师/经费事件。
- `doctor1_seminar_method_cards`：沙龙方法卡，补充沙龙与方法资源。

### 博二

- `doctor2_project_standup`：项目晨会站会，补充项目/会议/合作交流。
- `doctor2_equipment_maintenance_log`：设备维护日志，补充设备资源。
- `doctor2_collaborator_data_cleaning`：合作数据清洗，补充合作数据交流。
- `doctor2_fund_receipt_stack`：经费票据堆，补充经费/行政资源。

### 博三

- `doctor3_defense_question_bank`：答辩问题库，补充答辩方法资源。
- `doctor3_slide_backup_drive`：幻灯备份盘，补充答辩草稿资源。
- `doctor3_hallway_mock_defense`：走廊模拟答辩，补充同门/委员会交流。
- `doctor3_committee_signature_sheet`：委员签字单，补充答辩行政事件。

### 博四

- `doctor4_revision_data_recheck`：返修数据复核，补充返修数据交流。
- `doctor4_committee_response_table`：委员回复表，补充委员会/写作资源。
- `doctor4_peer_night_shift`：返修夜班同伴，补充同伴/自我照护交流。
- `doctor4_supplemental_defense_notice`：补答辩通知，补充补答辩行政事件。

## 实现记录

- [master1.tres](../../../data/campus/stages/master1.tres)
- [master2.tres](../../../data/campus/stages/master2.tres)
- [doctor1.tres](../../../data/campus/stages/doctor1.tres)
- [doctor2.tres](../../../data/campus/stages/doctor2.tres)
- [doctor3.tres](../../../data/campus/stages/doctor3.tres)
- [doctor4.tres](../../../data/campus/stages/doctor4.tres)

每个阶段新增 4 个 `CampusInteractionDefinition` sub-resource，并追加到 `generation_candidate_interactions`。`interactions` 固定地图列表保持不变。

## 验证记录

远程 Godot 执行器验证：

```text
scene_reload=0
master1 fixed=12,pool=20,source=candidate,count=12,pool=20,target=12,selected=12,missing_routes=,audit=pool=20,target=12,selected=12,missing=0,focus_hits=7/7
master2 fixed=12,pool=20,source=candidate,count=12,pool=20,target=12,selected=12,missing_routes=,audit=pool=20,target=12,selected=12,missing=0,focus_hits=7/7
doctor1 fixed=12,pool=20,source=candidate,count=12,pool=20,target=12,selected=12,missing_routes=,audit=pool=20,target=12,selected=12,missing=0,focus_hits=7/7
doctor2 fixed=12,pool=20,source=candidate,count=12,pool=20,target=12,selected=12,missing_routes=,audit=pool=20,target=12,selected=12,missing=0,focus_hits=6/6
doctor3 fixed=12,pool=20,source=candidate,count=12,pool=20,target=12,selected=12,missing_routes=,audit=pool=20,target=12,selected=12,missing=0,focus_hits=6/6
doctor4 fixed=12,pool=20,source=candidate,count=12,pool=20,target=12,selected=12,missing_routes=,audit=pool=20,target=12,selected=12,missing=0,focus_hits=6/6
```

布局抽查：

```text
master1 unique=7,max=导师办公室3
master2 unique=5,max=导师办公室4
doctor1 unique=5,max=导师办公室4
doctor2 unique=6,max=实验楼4
doctor3 unique=4,max=图书馆4
doctor4 unique=5,max=图书馆4
```

## 手测重点

1. 打开 `候选池地图`，测试区审查文本应显示 `pool=20,target=12,selected=12`。
2. 连续点击 `重随 Seed`，每阶段仍应保留剧情目标和 Boss 入口。
3. 研一应更容易看到文献、实验、自我照护等不同语义点。
4. 研二应更容易出现转博/盲审/复现实验相关候选。
5. 博三、博四应更容易出现答辩、委员会、返修和同伴支撑相关点位。
6. 图例应随候选点变化同步更新，且不需要正式 PNG 也能正常显示占位。

## 下一步

1. 候选池“阶段主题权重”已在 [134_campus_generation_theme_weighting.md](134_campus_generation_theme_weighting.md) 接入，让不同 Seed 下更明显出现写作型、实验型、社交型、答辩型校园日程。
2. 也可以继续进入卡牌/战斗层，补充与这些新校园点语义相连的奖励池和事件反馈。
