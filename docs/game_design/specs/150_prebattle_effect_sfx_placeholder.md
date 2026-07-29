# 150 携带开局效果占位音效

## 目标

承接 [149_prebattle_effect_chip_wrap_layout.md](149_prebattle_effect_chip_wrap_layout.md)，为携带物开局效果浮字加入轻量音效反馈。

当前还没有正式音频素材，因此本次不新增外部资源文件，而是在代码中生成短促的 `AudioStreamWAV` 占位音效。这样可以先验证反馈节奏和触发时机，后续正式音效完成后再替换为资源加载。

## 当前规则

- 战斗 UI 创建一个 `AudioStreamPlayer`，命名为 `PrebattleEffectAudioPlayer`。
- 优先输出到 `SFX` 总线；如果项目暂时没有 `SFX` 总线，则回退到 `Master`。
- 每条浮字真正开始播放时才触发音效。
- 如果多个开局效果进入浮字队列，音效也跟随队列逐条播放。
- 不同效果使用不同基础频率，形成轻微区分：
  - `opening_draw`：880 Hz。
  - `starting_block`：660 Hz。
  - `starting_progress`：740 Hz。
  - `first_turn_action_point`：990 Hz。
  - `pressure_reduction`：590 Hz。
  - `target_progress_reduction`：700 Hz。

## 实现记录

- [battle_test_scene.gd](../../../scripts/ui/battle_test_scene.gd)
  - 新增 `prebattle_effect_audio_player`。
  - 新增短音效生成常量：采样率、时长、attack 和振幅。
  - 新增 `_get_available_audio_bus()`。
  - 新增 `_play_prebattle_effect_sfx()`。
  - 新增 `_get_prebattle_effect_sfx_frequency()`。
  - 新增 `_create_prebattle_effect_sfx_stream()`。
  - `_show_prebattle_effect_feedback()` 在浮字显示时播放对应音效。
  - `_clear_prebattle_effect_feedback()` 会停止音效并重置测试计数。
  - 新增 `get_prebattle_effect_sfx_summary()` 和 `get_prebattle_effect_sfx_play_count()` 供自动验证。

## 验证记录

远程 Godot 执行器验证：

```text
battle_scene_reload=0
campus_scene_reload=0
choose_laptop=true
active_battle=true
sfx_after_first=player=true,count=1,last=opening_draw,freq=880,frames=3087,stream=AudioStreamWAV
second_apply=true
sfx_after_second=player=true,count=1,last=opening_draw,freq=880,frames=3087,stream=AudioStreamWAV
queue_count=1
chip_count=2
battle_hand=6
battle_block=4
```

队列推进验证：

```text
campus_scene_reload=0
before_finish=player=true,count=1,last=opening_draw,freq=880,frames=3087,stream=AudioStreamWAV
before_queue=1
after_finish=player=true,count=2,last=starting_block,freq=660,frames=3087,stream=AudioStreamWAV
after_queue=0
```

验证含义：

- 进入战斗时，笔记本电脑的 `opening_draw` 浮字会触发 1 次占位音效。
- 追加 `starting_block` 时，数值立即生效，但音效不会抢播。
- 第一条浮字结束后，第二条浮字开始播放，同时触发第二次音效。
- 占位音效使用内存生成的 `AudioStreamWAV`，没有新增临时素材文件。

## 手测重点

1. 住屋携带 `笔记本电脑` 后进入带携带物专属选项的战斗。
2. 选择笔记本电脑方案，进入战斗时应听到很短的提示音。
3. 后续若一场战斗有多个开局效果，音效应随浮字逐条出现。
4. 声音只作为轻量正反馈，不应盖过战斗操作反馈。

## 下一步

1. 后续美术素材完成后，将 `ColorRect` 占位色块替换为正式像素图标。
2. 后续音频素材完成后，将程序生成占位音效替换为正式短 SFX。
3. 等战斗 HUD 内容继续增多后，再统一做一轮移动端/窄屏排版验收。
