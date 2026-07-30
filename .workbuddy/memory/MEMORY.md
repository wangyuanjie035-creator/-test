# 项目长期记忆

## 项目概况
- 游戏名：《博三之前》— 研究生题材 Roguelite 策略游戏
- 引擎：Godot 4.5 + GDScript
- 核心概念：玩家在三年研究生生涯中管理不确定的研究课题，构筑科研方法
- 当前阶段：v0.5.0 一学年纵切片（机器闭环已完成，真人验证不足）

## 设计基线
- 当前生效 GDD：`GDD.md`（根目录）+ `docs/game_design/DUAL_TOPIC_GDD_V4.md`
- 2026-07-30 产出重设计文档：`docs/game_design/REDESIGN_V1_FUN_OVERHAUL.md`
- 平衡表：`docs/game_design/BALANCE_TUNING_V1.md`

## 关键技术决策
- 数据驱动：所有游戏内容使用 Godot Resource (.tres)
- 四层架构：数据层 → 模型层 → 会话层 → UI 层
- Seed 确定性：相同操作产生相同结果
- 不使用隐藏骰子

## 当前问题
- 核心玩法"不好玩"（老板反馈）
- 原因：填进度条式玩法、无动态对抗、卡牌设计浅、搜打撤张力未落地
- 重设计方案已输出，等待评审
