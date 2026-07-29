# MVP 规格索引

本目录存放已经从“候选想法”推进到“可纸面测试、可实现”的规格。这里的内容优先服务 MVP，不追求一次性覆盖完整游戏。

## 当前规格包

| 文档 | 内容 |
| --- | --- |
| [001_mvp_card_set.md](001_mvp_card_set.md) | 30 张基础卡、5 张博士线卡、初始牌组、负面状态牌和纸面数值基准 |
| [002_mvp_boss_set.md](002_mvp_boss_set.md) | 开题报告、中期考核、盲审专家三个 Boss 的机制 |
| [003_mvp_event_set.md](003_mvp_event_set.md) | 5 个 MVP 事件节点及选项结果 |
| [004_godot_data_model.md](004_godot_data_model.md) | Godot Resource 数据结构、目录规划和字段定义 |
| [005_paper_playtest_protocol.md](005_paper_playtest_protocol.md) | 纸面测试流程、记录表和调整原则 |
| [006_godot_data_layer_implementation.md](006_godot_data_layer_implementation.md) | 首批 Godot 数据层实现记录与验证结果 |
| [007_minimal_battle_state.md](007_minimal_battle_state.md) | 最小战斗状态规则、验收标准和实现边界 |
| [008_battle_test_ui.md](008_battle_test_ui.md) | 极简战斗测试界面、交互和验证记录 |
| [009_ordinary_pressure_encounter.md](009_ordinary_pressure_encounter.md) | 普通压力节点数据、敌方意图和 UI 接入 |
| [010_reward_selection.md](010_reward_selection.md) | 节点胜利后的三选一奖励和首批奖励卡 |
| [011_node_loop.md](011_node_loop.md) | 选择奖励后进入下一普通压力节点的局内闭环 |
| [012_route_state_and_encounter_variants.md](012_route_state_and_encounter_variants.md) | 固定 MVP 路线、路线状态和普通节点变体 |
| [013_run_settlement.md](013_run_settlement.md) | 阶段结算、Boss 坏结局和局外资源正反馈 |
| [014_meta_progression_save.md](014_meta_progression_save.md) | 局外资源 JSON 存档、累计规则和首个解锁钩子 |
| [015_first_meta_unlock_card.md](015_first_meta_unlock_card.md) | `self_care_seed` 接入 `U001 自我照护` 的首个真实局外解锁 |
| [016_meta_carryover_preview.md](016_meta_carryover_preview.md) | 新旅程开局时展示局外带入、累计资源和解锁名称 |
| [017_clear_test_meta_save.md](017_clear_test_meta_save.md) | 受保护的清空测试局外存档按钮与验证记录 |
| [018_second_meta_unlock_card.md](018_second_meta_unlock_card.md) | `paper_fragments` 接入 `U002 返修策略` 的第二个局外解锁 |
| [019_event_nodes_in_route.md](019_event_nodes_in_route.md) | `E001`、`E004` 事件节点接入固定路线和结算闭环 |
| [020_route_map_and_event_feedback.md](020_route_map_and_event_feedback.md) | 测试 UI 路线条、事件选择实际结果反馈和验证记录 |
| [021_manual_playtest_guide.md](021_manual_playtest_guide.md) | Godot 手动运行测试步骤、事件选项说明和跳代码排查方法 |
| [022_branching_route_choice.md](022_branching_route_choice.md) | 节点完成后的 2-3 个下一节点候选、动态路线和分叉验证 |
| [023_first_boss_node.md](023_first_boss_node.md) | `B001 开题报告` Boss 节点、意图循环、路线接入和验证记录 |
| [024_boss_readability_and_rewards.md](024_boss_readability_and_rewards.md) | Boss 战意图提示、阶段检查提示和 Boss 专属胜利奖励 |
| [025_proposal_delay_settlement.md](025_proposal_delay_settlement.md) | `B001 开题延期` 失败结算、局外资源和验证记录 |
| [026_settlement_visual_hierarchy.md](026_settlement_visual_hierarchy.md) | 阶段通过、精力耗尽和 Boss 坏结局结算的分层 UI |
| [027_boss_reward_visuals.md](027_boss_reward_visuals.md) | Boss 胜利奖励的专属面板、按钮样式和验证记录 |
| [028_second_boss_midterm_review.md](028_second_boss_midterm_review.md) | `B002 中期考核` Boss 节点、路线接入、中期预警和验证记录 |
| [029_b002_material_checklist.md](029_b002_material_checklist.md) | `B002` 材料清单的本战累计数据/草稿追踪 |
| [030_b002_reward_pool.md](030_b002_reward_pool.md) | `B002` 专属奖励池：材料归档、复现实验流程和实验噪音清理 |
| [031_post_midterm_transfer_branch.md](031_post_midterm_transfer_branch.md) | `B002` 后转博/不转博分支的路线锚点和后续接入契约 |
| [032_third_boss_blind_review.md](032_third_boss_blind_review.md) | `B003 盲审专家` Boss 节点、不转博硕士毕业线和盲审未过结算 |
| [033_b003_graduation_endings.md](033_b003_graduation_endings.md) | `B003` 胜利后的优秀毕业、顺利毕业和擦线毕业结局选择 |
| [034_transfer_application_event.md](034_transfer_application_event.md) | `E005 转博申请` 分支事件、条件检查和转博资格确认结算 |
| [035_doctoral_route_entry.md](035_doctoral_route_entry.md) | `N005 博一开题重构` 博士线入口和 E005 后续路线 |
| [036_b004_doctoral_qualification.md](036_b004_doctoral_qualification.md) | `B004 博士资格考核` Boss、资格审查和博士线坏结局 |
| [037_doctor2_project_pressure.md](037_doctor2_project_pressure.md) | `N006 项目推进压力` 博二普通节点和 B004 后续路线 |
| [038_doctor2_funding_window.md](038_doctor2_funding_window.md) | `E006 基金申请窗口` 博二事件、基金/论文/横向项目取舍 |
| [039_b005_project_midterm.md](039_b005_project_midterm.md) | `B005 项目中期检查` Boss、经费/数据/论文管线检查和坏结局 |
| [040_doctor3_predefense_prep.md](040_doctor3_predefense_prep.md) | `N007 预答辩筹备` 博三入口普通节点和 B005 后续路线 |
| [041_b006_doctoral_predefense.md](041_b006_doctoral_predefense.md) | `B006 博士预答辩` Boss、预答辩材料检查和坏结局 |
| [042_doctoral_reward_pool.md](042_doctoral_reward_pool.md) | 博士线普通节点专属奖励池和 5 张博士线卡 |
| [043_b007_doctoral_defense.md](043_b007_doctoral_defense.md) | `B007 博士答辩` 终局 Boss、博士毕业和答辩延期 |
| [044_b007_graduation_endings.md](044_b007_graduation_endings.md) | `B007` 胜利后的优秀博士毕业、博士毕业和延毕后毕业结局选择 |
| [045_doctoral_boss_reward_pool.md](045_doctoral_boss_reward_pool.md) | `B004` 到 `B006` 博士 Boss 专属胜利奖励池 |
| [046_doctoral_delay_repair_event.md](046_doctoral_delay_repair_event.md) | `B007` 失败后的 `E007 博四返修会` 和博四返修短路线入口 |
| [047_doctor4_revision_route.md](047_doctor4_revision_route.md) | `E007 -> N008 -> B008` 博四返修短路线 |
| [048_supplementary_failure_meta_unlock.md](048_supplementary_failure_meta_unlock.md) | `补答辩再延期` 专属局外解锁 `U003 返修矩阵` |
| [049_settlement_unlock_highlight.md](049_settlement_unlock_highlight.md) | 结算页单独高亮显示新解锁和下局带入 |
| [050_settlement_section_layout.md](050_settlement_section_layout.md) | 结算页资源变化、新解锁和下局带入分区布局 |
| [051_settlement_itemized_entries.md](051_settlement_itemized_entries.md) | 结算页资源、新解锁和带入卡的条目化文本 |
| [052_settlement_entry_rows.md](052_settlement_entry_rows.md) | 结算页资源、新解锁和带入卡的真实 UI 行 |
| [053_build_archetype_framework.md](053_build_archetype_framework.md) | 第二阶段构筑流派、标签规范和奖励池分层 |
| [054_card_tag_audit.md](054_card_tag_audit.md) | 现有卡牌的构筑流派归类、标签缺口和补标签建议 |
| [055_card_tag_patch.md](055_card_tag_patch.md) | 按审计结果为现有卡牌补充安全构筑标签 |
| [056_first_archetype_cards.md](056_first_archetype_cards.md) | 第一批设备、导师和 DDL 流派卡及节点奖励池接入 |
| [057_project_revision_archetype_cards.md](057_project_revision_archetype_cards.md) | 项目经费流和返修延毕流卡牌及奖励池接入 |
| [058_reward_archetype_hint_ui.md](058_reward_archetype_hint_ui.md) | 奖励三选一卡牌的流派提示和中文标签 tooltip |
| [059_experiment_noise_cards.md](059_experiment_noise_cards.md) | 实验噪音负面牌、清理实验台和实验节点奖励池扩展 |
| [060_experiment_noise_route_integration.md](060_experiment_noise_route_integration.md) | `E003 设备坏了` 和 `B002` 数据检查接入实验噪音 |
| [061_negative_result_conversion_card.md](061_negative_result_conversion_card.md) | `C028 负结果也是结果` 将实验噪音转化为数据和灵感 |
| [062_equipment_maintenance_card.md](062_equipment_maintenance_card.md) | `C038 设备维护记录` 将经费转化为数据和方法论笔记 |
| [063_weighted_reward_selection.md](063_weighted_reward_selection.md) | 普通节点候选池按构筑标签加权后裁剪为三选一 |
| [064_reward_recommendation_tooltip.md](064_reward_recommendation_tooltip.md) | 奖励 tooltip 显示同流派加权推荐原因 |
| [065_node_reward_pool_expansion.md](065_node_reward_pool_expansion.md) | `N002` 扩展为 5 张普通节点候选池并新增 `C039 会后纪要` |
| [066_n001_reward_pool_expansion.md](066_n001_reward_pool_expansion.md) | `N001` 扩展为 5 张普通节点候选池并新增 `C040 研究问题清单` |
| [067_n004_reward_pool_expansion.md](067_n004_reward_pool_expansion.md) | `N004` 扩展为 5 张普通节点候选池并新增 `C041 截稿后复盘` |
| [068_weighted_reward_random_selection.md](068_weighted_reward_random_selection.md) | 普通节点大候选池按构筑分数进行带权随机三选一 |
| [069_run_seed_randomization.md](069_run_seed_randomization.md) | 新旅程随机 seed、状态栏显示 seed，并提供指定 seed 复现入口 |
| [070_seed_debug_controls.md](070_seed_debug_controls.md) | UI 中提供 seed 输入框、复制 seed 和按 seed 重开调试控件 |
| [071_settlement_seed_display.md](071_settlement_seed_display.md) | 结算页统计行显示本局 seed，方便截图反馈和复现 |
| [072_route_choice_seed_shuffle.md](072_route_choice_seed_shuffle.md) | 下一节点候选根据本局 seed 进行稳定洗牌 |
| [073_early_route_candidate_pool_expansion.md](073_early_route_candidate_pool_expansion.md) | 早期路线候选池首版扩展，让 seed 影响候选内容 |
| [074_route_choice_weighting.md](074_route_choice_weighting.md) | 下一节点候选根据当前牌组标签和资源倾向加权 |
| [075_route_choice_recommendation_tooltip.md](075_route_choice_recommendation_tooltip.md) | 下一节点候选 tooltip 显示构筑推荐原因 |
| [076_route_choice_card_buttons.md](076_route_choice_card_buttons.md) | 下一节点候选按钮升级为显示类型、风险和奖励倾向的节点卡片 |
| [077_early_route_new_nodes.md](077_early_route_new_nodes.md) | 新增 `N009 数据清洗夜` 和 `E008 导师临时约谈` 并接入早期路线池 |
| [078_route_node_hint_data_table.md](078_route_node_hint_data_table.md) | 将路线节点卡片提示、强调色和路线权重外置为 Resource 数据表 |
| [079_route_node_detail_panel.md](079_route_node_detail_panel.md) | 下一节点候选详情面板，预览风险、奖励、事件选项和 Boss 检查 |
| [080_route_detail_structured_rows.md](080_route_detail_structured_rows.md) | 将路线详情预览改成奖励、事件选项和 Boss 检查的结构化行 |
| [081_transfer_branch_requirements.md](081_transfer_branch_requirements.md) | `E005 转博申请` 的资格条件进度、详情行和分支跳转验证 |
| [082_event_requirement_progress.md](082_event_requirement_progress.md) | 事件选项条件显示为当前资源进度，例如 `草稿 0/2` 与 `声望 1/1` |
| [083_2d_campus_overworld_mvp.md](083_2d_campus_overworld_mvp.md) | 2D 像素校园地图首版，接入 NPC、资源点和现有卡牌战斗入口 |
| [084_campus_map_layout_fix.md](084_campus_map_layout_fix.md) | 修正校园地图尺寸、建筑布局、玩家初始位置和 Camera2D 边界 |
| [085_campus_battle_result_writeback.md](085_campus_battle_result_writeback.md) | 校园地图记录学术交流完成状态，并回写战斗/事件资源变化 |
| [086_campus_resource_carry_into_battle.md](086_campus_resource_carry_into_battle.md) | 校园资源注入卡牌战斗层，并在完成后同步正负资源差值 |
| [087_campus_resource_points_expansion.md](087_campus_resource_points_expansion.md) | 扩展校园地图资源点，并统一资源收集完成状态 |
| [088_campus_resource_visual_feedback.md](088_campus_resource_visual_feedback.md) | 为校园资源点增加分类像素图标、脉冲提示和拾取浮字 |
| [089_campus_marker_componentization.md](089_campus_marker_componentization.md) | 将校园交互逻辑和地图标记视觉拆分为可复用组件 |
| [090_campus_marker_state_variants.md](090_campus_marker_state_variants.md) | 为校园地图标记增加剧情关键、条件不足和 Boss 可挑战状态 |
| [091_campus_stage_interaction_pools.md](091_campus_stage_interaction_pools.md) | 为研一、研二和博一建立阶段化校园交互池 |
| [092_campus_stage_debug_controls.md](092_campus_stage_debug_controls.md) | 在校园 HUD 中增加研一、研二、博一阶段切换调试按钮 |
| [093_campus_condition_locked_requirements.md](093_campus_condition_locked_requirements.md) | 将校园条件不足标记绑定到真实资源需求和交互摘要 |
| [094_campus_data_resource_migration.md](094_campus_data_resource_migration.md) | 将校园阶段交互池和路线条件表迁移为 Resource 数据 |
| [095_campus_doctoral_stage_expansion.md](095_campus_doctoral_stage_expansion.md) | 扩展博二、博三和博四返修校园阶段 |
| [096_campus_story_stage_progression.md](096_campus_story_stage_progression.md) | 将校园阶段切换接入正式剧情推进和转博分支 |
| [097_campus_story_guidance.md](097_campus_story_guidance.md) | 在校园地图和 HUD 中高亮下一剧情节点 |
| [098_campus_condition_soft_gate.md](098_campus_condition_soft_gate.md) | 条件不足关键节点首次交互提示，二次确认才进入 |
| [099_campus_requirement_intercept_modes.md](099_campus_requirement_intercept_modes.md) | 将校园条件不足入口行为配置为仅提示、二次确认或硬拦截 |
| [100_campus_guidance_supply_advice.md](100_campus_guidance_supply_advice.md) | 在下一剧情 HUD 中追加可执行的资源补足建议 |
| [101_campus_supply_hint_marker_highlight.md](101_campus_supply_hint_marker_highlight.md) | 将 HUD 补足建议同步为地图上的补给点高亮 |
| [102_campus_guidance_legend.md](102_campus_guidance_legend.md) | 在校园 HUD 中加入青色剧情目标与金色补给点图例 |
| [103_campus_focus_prompt_role_tags.md](103_campus_focus_prompt_role_tags.md) | 在校园靠近提示中显示剧情目标与建议补给角色标签 |
| [104_campus_marker_focus_feedback.md](104_campus_marker_focus_feedback.md) | 玩家靠近校园交互点时显示像素聚焦反馈 |
| [105_campus_pickup_burst_feedback.md](105_campus_pickup_burst_feedback.md) | 资源拾取时增加像素光点爆闪反馈 |
| [106_campus_battle_transition_feedback.md](106_campus_battle_transition_feedback.md) | 从校园进入学术交流时显示短暂转场提示 |
| [107_campus_return_transition_feedback.md](107_campus_return_transition_feedback.md) | 从学术交流返回校园时显示结果提示 |
| [108_campus_return_summary_panel.md](108_campus_return_summary_panel.md) | 从学术交流返回校园后显示结果、资源和下一步摘要 |
| [109_campus_summary_next_step_link.md](109_campus_summary_next_step_link.md) | 将返回摘要中的下一步目标与地图剧情目标强化联动 |
| [110_campus_marker_pulse_rhythm.md](110_campus_marker_pulse_rhythm.md) | 调整校园地图多层标记的脉冲节奏与叠加强度 |
| [111_campus_guidance_direction_indicator.md](111_campus_guidance_direction_indicator.md) | 为屏幕边缘的下一剧情目标增加 HUD 方向提示 |
| [112_campus_target_discovery_rhythm.md](112_campus_target_discovery_rhythm.md) | 返回校园后短时强调下一剧情目标方向 |
| [113_campus_hud_visual_hierarchy.md](113_campus_hud_visual_hierarchy.md) | 整理校园 HUD 提示层级与方向箭头安全区域 |
| [114_campus_hud_information_density.md](114_campus_hud_information_density.md) | 将校园左上 HUD 拆分为状态、资源、目标、日志和测试区 |
| [115_campus_stage_interaction_variety_pack.md](115_campus_stage_interaction_variety_pack.md) | 为每个校园阶段新增学术交流点和补给点 |
| [116_campus_interactable_density_audit.md](116_campus_interactable_density_audit.md) | 为校园交互点生成加入建筑、边界和近邻避让 |
| [117_campus_marker_role_silhouettes.md](117_campus_marker_role_silhouettes.md) | 强化学术交流、事件、Boss 和补给点的像素轮廓差异 |
| [118_campus_focus_info_card.md](118_campus_focus_info_card.md) | 靠近校园点位时显示类型、路线、收益和准备信息卡 |
| [119_campus_content_tags.md](119_campus_content_tags.md) | 为校园点位增加导师、同门、会议、补给等内容标签 |
| [120_campus_task_tracker_placeholder.md](120_campus_task_tracker_placeholder.md) | 在右上 HUD 增加校园任务视图和小地图占位 |
| [121_campus_task_tracker_minimap_points.md](121_campus_task_tracker_minimap_points.md) | 将任务视图小地图占位升级为像素点位图 |
| [122_campus_tag_driven_generation_draft.md](122_campus_tag_driven_generation_draft.md) | 为校园随机地图建立阶段标签配方和审查接口 |
| [123_campus_tag_candidate_selector.md](123_campus_tag_candidate_selector.md) | 按阶段标签配方预览稳定选择校园候选点位 |
| [124_campus_candidate_pool_expansion.md](124_campus_candidate_pool_expansion.md) | 将校园固定地图点位与生成候选池拆分，并把每阶段候选池扩到 16 个 |
| [125_campus_candidate_spawn_toggle.md](125_campus_candidate_spawn_toggle.md) | 增加候选池地图调试开关，让实际校园可切到候选池生成结果 |
| [126_campus_seed_reroll_debug.md](126_campus_seed_reroll_debug.md) | 增加校园重随 Seed 调试按钮，用于验证候选地图复现与差异 |
| [127_campus_candidate_layout_weighting.md](127_campus_candidate_layout_weighting.md) | 为候选池地图增加区域布局再平衡，避免点位过度集中 |
| [128_campus_candidate_audit_panel.md](128_campus_candidate_audit_panel.md) | 在测试区显示候选地图审查面板，集中展示 seed、路线、标签和布局 |
| [129_campus_marker_visual_variety_placeholders.md](129_campus_marker_visual_variety_placeholders.md) | 为候选点增加导师、同门、设备、答辩、补给等像素风视觉占位 |
| [130_campus_marker_profile_legend.md](130_campus_marker_profile_legend.md) | 在测试区显示当前地图实际出现的点位 profile 图例 |
| [131_campus_art_asset_replacement_checklist.md](131_campus_art_asset_replacement_checklist.md) | 按 marker profile 制定正式像素素材替换清单与导入验收标准 |
| [132_campus_marker_texture_fallback.md](132_campus_marker_texture_fallback.md) | 为校园点位接入 profile 贴图优先、缺图代码占位 fallback |
| [133_campus_candidate_pool_20_expansion.md](133_campus_candidate_pool_20_expansion.md) | 将每阶段校园生成候选池扩展到 20 个，同时保持实际刷出 12 个 |
| [134_campus_generation_theme_weighting.md](134_campus_generation_theme_weighting.md) | 为候选池地图加入 Seed 可复现的阶段主题权重 |
| [135_campus_generation_theme_choices.md](135_campus_generation_theme_choices.md) | 将校园生成主题从自动决定改为肉鸽式三选一 |
| [136_safehouse_campus_day_loop.md](136_safehouse_campus_day_loop.md) | 增加住屋安全屋、出门主题选择、校园探索返回和下一天循环 |
| [137_safehouse_map_entrance.md](137_safehouse_map_entrance.md) | 将安全返回住屋升级为校园地图上的宿舍入口交互点 |
| [138_safehouse_return_transition.md](138_safehouse_return_transition.md) | 为住屋入口加入安全撤回转场反馈 |
| [139_safehouse_prep_attributes.md](139_safehouse_prep_attributes.md) | 增加住屋准备行动、智性/情性成长和出门地图倾向 |
| [140_safehouse_carry_slots.md](140_safehouse_carry_slots.md) | 将携带物升级为 2 槽物品选择并影响校园地图倾向 |
| [141_carry_item_interaction_triggers.md](141_carry_item_interaction_triggers.md) | 让携带物在匹配校园点位中触发具体资源收益 |
| [142_carry_item_exclusive_options.md](142_carry_item_exclusive_options.md) | 让携带物在非资源点位中提供专属处理选项 |
| [143_carry_choice_panel.md](143_carry_choice_panel.md) | 将携带物专属选项升级为进入战斗前的可点击选择面板 |
| [144_carry_choice_battle_effects.md](144_carry_choice_battle_effects.md) | 为携带物选择加入资源之外的战斗开局修正 |
| [145_prebattle_effect_hud_hint.md](145_prebattle_effect_hud_hint.md) | 在战斗界面显示携带物开局效果短提示 |
| [146_prebattle_effect_flash_feedback.md](146_prebattle_effect_flash_feedback.md) | 为携带物开局效果增加进入战斗瞬间的浮字反馈 |
| [147_prebattle_effect_chips.md](147_prebattle_effect_chips.md) | 将携带物开局效果提示升级为彩色 chip 占位图标 |
| [148_prebattle_effect_feedback_queue.md](148_prebattle_effect_feedback_queue.md) | 让多个携带物开局效果浮字按队列顺序播放 |
| [149_prebattle_effect_chip_wrap_layout.md](149_prebattle_effect_chip_wrap_layout.md) | 让携带物开局效果 chip 支持换行和稳定宽度 |
| [150_prebattle_effect_sfx_placeholder.md](150_prebattle_effect_sfx_placeholder.md) | 为携带物开局效果浮字加入程序生成的占位音效 |

## 使用方式

1. 纸面测试时，以 `001` 到 `003` 为规则源。
2. 进入 Godot 实现时，以 `004` 为数据模型源。
3. 测试后把问题记录到 `005`，再回到对应规格修正。
4. 任何和旧文档冲突的地方，以本目录规格为准，并在 `../DECISIONS.md` 记录重大取舍。
