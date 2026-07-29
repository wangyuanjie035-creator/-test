# 115 校园阶段交互丰富度包

## 目标

承接 [114_campus_hud_information_density.md](114_campus_hud_information_density.md)，补强 2D 校园地图本身的探索内容。当前主线、Boss 和资源回写已经跑通，但地图点位仍偏“功能入口”，这一步为每个学历阶段新增一个普通学术交流点和一个小额补给点，让校园更像可走动探索的回合制卡牌 RPG 场景。

本步只扩展 `CampusInteractionDefinition` 数据，不新增路线节点、不修改战斗、不修改剧情推进和转博分支。

## 新增内容

| 阶段 | 新增学术交流 | 路线 | 新增补给 | 资源 |
|---|---|---|---|---|
| 研一 | 读书会追问 | `N001` | 同门联系卡 | `reputation +1` |
| 研二 | 预印本争论 | `N002` | 送审清单 | `methodology_notes +1` |
| 博一 | 博士沙龙追问 | `N002` | 资格考模拟题 | `methodology_notes +1` |
| 博二 | 跨组协调会 | `N006` | 合作方反馈邮件 | `reputation +1` |
| 博三 | 委员会模拟问答 | `N007` | 答辩计时表 | `methodology_notes +1` |
| 博四 | 返修互审会 | `N004` | 返修补给餐 | `inspiration +1` |

## 设计规则

- 每个阶段新增 2 个校园点，使阶段交互数量从 10 提升到 12。
- 新增学术交流复用已有普通路线节点，保证可以直接进入现有卡牌战斗/事件流程。
- 新增补给点给小额正反馈，避免资源膨胀，同时回应“失败后也能获得资源、能力、再来一次”的长期方向。
- 点位分布优先放在图书馆、导师办公室、食堂或会议室附近，保持校园空间语义。
- 新增内容不设置 `story_key`，避免抢主线引导目标。
- 后续替换像素素材时，这些名字可直接映射到 NPC、便签、邮件、清单、餐盒等具体对象。

## 实现记录

- [master1.tres](../../../data/campus/stages/master1.tres)
  - 新增 `Interaction_reading_group_quiz`
  - 新增 `Interaction_peer_contact_card`
- [master2.tres](../../../data/campus/stages/master2.tres)
  - 新增 `Interaction_preprint_discussion`
  - 新增 `Interaction_review_checklist`
- [doctor1.tres](../../../data/campus/stages/doctor1.tres)
  - 新增 `Interaction_doctoral_seminar_challenge`
  - 新增 `Interaction_qualification_mock_questions`
- [doctor2.tres](../../../data/campus/stages/doctor2.tres)
  - 新增 `Interaction_cross_group_coordination`
  - 新增 `Interaction_partner_feedback_mail`
- [doctor3.tres](../../../data/campus/stages/doctor3.tres)
  - 新增 `Interaction_committee_mock_qna`
  - 新增 `Interaction_defense_timer_sheet`
- [doctor4.tres](../../../data/campus/stages/doctor4.tres)
  - 新增 `Interaction_revision_peer_review`
  - 新增 `Interaction_repair_energy_snack`

## 验证记录

数据资源加载验证：
```text
master1_data_count=12, master1_missing_new=
master2_data_count=12, master2_missing_new=
doctor1_data_count=12, doctor1_missing_new=
doctor2_data_count=12, doctor2_missing_new=
doctor3_data_count=12, doctor3_missing_new=
doctor4_data_count=12, doctor4_missing_new=
```

校园场景实例化验证：
```text
campus_reload=0
master1_spawned_count=12, guidance_target=proposal_room
master2_spawned_count=12, guidance_target=midterm_room
doctor1_spawned_count=12, guidance_target=doctoral_problem_chain
doctor2_spawned_count=12, guidance_target=doctor2_project_pressure_board
doctor3_spawned_count=12, guidance_target=doctor3_predefense_prep
doctor4_spawned_count=12, guidance_target=doctor4_delay_repair_meeting
```

## 手测重点

1. 通过左上 `测试` 区切换研一到博四，每个阶段地图上都应有 12 个可交互点。
2. 新增学术交流点靠近后，底部提示应显示名称和对应路线 ID。
3. 新增补给点拾取后，应出现资源浮字、像素爆闪，并从地图上消失。
4. 新增点不应覆盖主线剧情目标、Boss 点和已有补给点。
5. 主线 HUD 下一步仍应优先指向原有剧情目标，而不是新增的可选点。

## 下一步

1. 已完成：校园点位密度与避让审查已加入建筑、边界和近邻避让，见 [116_campus_interactable_density_audit.md](116_campus_interactable_density_audit.md)。
2. 可以继续扩展 NPC 表现：给不同 interaction_kind 加更多像素风角色轮廓、场景小物或漂浮提示。
